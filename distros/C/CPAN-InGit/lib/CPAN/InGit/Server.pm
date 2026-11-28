package CPAN::InGit::Server;
our $VERSION = '0.007'; # VERSION
# ABSTRACT: A Mojolicious::Controller that serves the ArchiveTrees from a git repo


use Carp;
use Scalar::Util 'refaddr', 'blessed';
use JSON::PP;
use Time::Piece;
use Log::Any '$log';
use IO::Compress::Gzip qw( gzip $GzipError );
use CPAN::InGit;
use CPAN::InGit::DistTree;
use File::ShareDir ();
use Mojo::File 'path';
use Mojo::Util 'url_escape';
use Mojolicious::Static;
use Mojo::Base 'Mojolicious::Controller';
use version ();
use v5.36;


sub cpan_repo($c) { $c->stash('cpan_repo') }

# Resolve each namespace directly, without falling back to another namespace.
sub _tree_object($class, $repo, $tree_name, $branch_head_only=0) {
   return undef unless defined $tree_name
      && $tree_name =~ m{\A~(branch|tag|commit)/([^/]+)\z};
   my ($kind, $name)= ($1, $2);
   return undef if $branch_head_only && $kind ne 'branch';
   $name =~ tr{~}{/};
   return eval {
      $kind eq 'branch'? Git::Raw::Branch->lookup($repo->git_repo, $name, 1)
      : $kind eq 'tag'? Git::Raw::Reference->lookup("refs/tags/$name", $repo->git_repo)
      : $name =~ /\A[0-9a-fA-F]{40}\z/? Git::Raw::Commit->lookup($repo->git_repo, $name)
      : undef;
   };
}

sub archive_tree($c) {
   $c->stash->{archive_tree} //= $c->_archive_tree_for($c->tree_name);
}

sub _archive_tree_for($c, $tree_name) {
   return undef unless defined $tree_name;
   my $cache= $c->tree_cache;
   my $object= $c->_tree_object($c->cpan_repo, $tree_name, $c->branch_head_only);
   my $current_tree= $object && eval { $c->cpan_repo->lookup_tree($object) };
   my $atree= $cache->{$tree_name};
   if ($atree && (!$current_tree || $atree->tree->id ne $current_tree->id)) {
      delete $cache->{$tree_name};
      $atree= undef;
   }
   if (!$atree && $current_tree) {
      $atree= $c->cpan_repo->get_archive_tree($object);
      if ($atree) {
         # reconstruct actual name for ArchiveTree->name attribute
         (my $name= $tree_name) =~ s{^~[^/]+/}{};
         $name =~ tr{~}{/};
         $atree->name($name);
         $cache->{$tree_name}= $atree;
      }
   }
   return $atree;
}

sub tree_name($c) {
   my $n= $c->stash('tree_name');
   return $n if defined $n;
   # back-compat: check "branch_name"
   $n= $c->stash('branch_name');
   return "~branch/".($n =~ tr{/}{~}r) if $n;
   return undef;
}

sub tree_cache($c) {
   # back-compat: check "branch_cache"
   $c->stash->{tree_cache} //= $c->stash->{branch_cache} // do {
      warn "no tree_cache or branch_cache, creating temporary";
      $c->_new_cache
   }
}

sub branch_head_only($c) { $c->stash('branch_head_only') }
sub index_branches($c) { $c->stash('index_branches') }
sub module_index_max_rows($c) { $c->stash('module_index_max_rows') // 5000 }

sub _share_dir {
   state $dir= do {
      my $relative= path(__FILE__)->sibling('..', '..', '..', 'share');
      -f $relative->child('archive_tree_index.html.ep')? $relative->realpath
         : path(File::ShareDir::dist_dir('CPAN-InGit'));
   };
   return $dir;
}

sub _new_cache {
   # the 'recent_limit' feature was added in 0.20
   state $have_tree_rb_xs= eval 'use Tree::RB::XS 0.20';
   my %hash;
   tie %hash, 'Tree::RB::XS', track_recent => 1, recent_limit => 20
      if $have_tree_rb_xs;
   \%hash;
}


sub mount($class, $base_route, $cpan_repo, %options) {
   my $atree= $options{archive_tree};
   my $app= delete $options{app};
   # Single-tree mounts also cache any configured import source branches.
   $options{branch_cache} //= $class->_new_cache
      unless defined $options{tree_cache};
   # This function could be called multiple times to mount various repos at different paths,
   # so each instance needs a different route namespace.
   # The route_ns is added as a stash attribute and used by actions when generating URLs.
   my $route_ns= 'cpan_ingit_'.++$base_route->root->{_cpan_ingit_mount_count};
   # Create or open the cache of unpacked distributions before workers fork
   $cpan_repo->dist_cache_repo;
   my $configured_route= $base_route->to(
      namespace => '',
      controller => $class,
      cpan_ingit_route_ns => $route_ns,
      cpan_repo => $cpan_repo,
      %options
   );
   # Register static before the catch-all branch index, and serve only the captured path
   # so static lookup does not depend on how deeply the application is mounted.
   my $static= Mojolicious::Static->new(paths => [$class->_share_dir->child('public')->to_string]);
   $configured_route->get('/~static/*asset')->to(cb => sub($c) {
      local $c->stash->{path}= $c->stash('asset');
      $static->dispatch($c) || $c->reply->not_found;
   })->name("$route_ns.assets");
   # If serving all branches, capture the branch from however many path components match,
   # then differentiate the tree route from the base route.
   my $tree_route= $configured_route;
   if ($atree) {
      croak "Not an ArchiveTree"
         unless blessed($atree) && $atree->can('get_path');
   } else {
      $configured_route->get('/')->to(action => 'serve_repo_index');
      $app or croak 'Multi-tree mounts require the app => $app option';
      $class->_install_tree_rewrite($app, $base_route, $cpan_repo, $options{branch_head_only});
      $tree_route= $configured_route->any('/*tree_name',
         [tree_name => $options{branch_head_only}? qr{~branch/[^/]+} : qr{~(?:branch|tag|commit)/[^/]+} ]);
   }
   $tree_route->get('/modules/02packages.details', [ format => ['txt','txt.gz'] ])
      ->to(action => 'serve_package_details');
   $tree_route->get('/authors/id/*author_path')->to(action => 'serve_author_file')->name("$route_ns.authors");
   $tree_route->get('/modules/')->to(action => 'serve_module_list')->name("$route_ns.modules");
   $tree_route->get('/', [ format => 0 ])
      ->to(action => 'serve_index')->name("$route_ns.index");
}

# Resolve friendly paths before Mojo computes its routing-cache key. Stop at
# this app's routes even when the app is embedded in another application.
sub _install_tree_rewrite($class, $app, $base_route, $repo, $branch_head_only) {
   my @patterns;
   for (my $route= $base_route; ; $route= $route->parent) {
      croak 'Mount route does not belong to app' unless $route;
      last if refaddr($route) == refaddr($app->routes);
      unshift @patterns, $route->pattern;
   }
   $app->hook(before_routes => sub($c) {
      my $original= $c->stash->{path} // $c->req->url->path->to_route;
      $original= "/$original" unless $original =~ m{^/};
      my $remaining= $original;
      for my $pattern (@patterns) {
         return unless $pattern->match_partial(\$remaining, 0);
      }
      return if $remaining eq '' || $remaining eq '/' || $remaining =~ m{^/~};
      my $prefix= substr($original, 0, length($original)-length($remaining));
      my @parts;
      while ($remaining =~ m{\G/([^/]+)}gc) {
         push @parts, $1;
         my $name= join '/', @parts;
         my $canonical;
         if (eval { Git::Raw::Branch->lookup($repo->git_repo, $name, 1) }) {
            $canonical= '~branch/'.join('~',@parts);
         } elsif (!$branch_head_only) {
            if (eval { Git::Raw::Reference->lookup("refs/tags/$name", $repo->git_repo) }) {
               $canonical= '~tag/'.join('~',@parts);
            }
            elsif (@parts == 1 && $name =~ /\A[0-9a-fA-F]{6,40}\z/
                  && (my $commit= eval { Git::Raw::Commit->lookup($repo->git_repo, $name) })
            ) {
               $canonical= '~commit/'.$commit->id;
            }
            # HEAD is a friendly alias, not an explicit branch name.
            elsif ($name eq 'HEAD') {
               my $commit= eval { $repo->git_repo->head->peel('commit') };
               $canonical= '~commit/'.$commit->id if $commit;
            }
         }
         next unless $canonical;
         $c->stash->{path}= "$prefix/$canonical".substr($remaining, pos($remaining));
         last;
      }
   });
}


sub serve_repo_index($c) {
   my @branches;
   my $index_branches= $c->index_branches // 0;
   if ($index_branches) {
      for my $branch (sort { $a->shorthand cmp $b->shorthand } $c->cpan_repo->git_repo->branches('local')) {
         my $tree= $branch->peel('tree');
         next unless $tree->entry_bypath('cpan_ingit.json')
            && $tree->entry_bypath('modules/02packages.details.txt');
         my $name= $branch->shorthand;
         push @branches, { name => $name, url => $c->_branch_index_url($name) };
      }
   }
   $c->render(inline => $c->_share_dir->child('repo_index.html.ep')->slurp('UTF-8'), handler => 'ep', format => 'html',
      index_branches => $index_branches, branches => \@branches);
}


sub _branch_selector($c, $name) { '~branch/'.($name =~ tr{/}{~}r) }

sub _branch_index_url($c, $name) {
   my $route_ns= $c->stash('cpan_ingit_route_ns');
   return $c->url_for("$route_ns.index", tree_name => $c->_branch_selector($name))->path->trailing_slash(1);
}

sub _module_index($c, $atree, $as_source=0) {
   # Source comparisons use the Git index snapshot and do not trigger mirror autofetch.
   my $blob;
   if ($as_source) {
      my $entry= $atree->tree->entry_bypath('modules/02packages.details.txt');
      $blob= $entry->object if $entry;
   } else {
      $blob= $atree->package_details_blob;
   }
   return undef unless $blob && $blob->is_blob;
   my $cache_key= $as_source? '_server_source_index' : '_server_module_index';
   my $index= $atree->{$cache_key};
   unless ($index && $index->{blob_id} eq $blob->id) {
      my ($headers, $body)= split /\r?\n\r?\n/, $blob->content, 2;
      my ($updated)= ($headers // '') =~ /^Last-Updated:[ \t]*([^\r\n]*)/m;
      my @rows;
      for my $line (split /\r?\n/, $body // '') {
         next unless $line =~ /^(\S+)\s+(\S+)\s+(\S+)\s*$/;
         push @rows, { name => $1, version => $2, path => $3, text => $line };
      }
      $index= $atree->{$cache_key}= { blob_id => $blob->id, updated => $updated };
      if ($as_source) {
         # in the format of ArchiveTree->package_details
         $index->{by_module}= { map +( $_->{name} => [ $_->{name}, ($_->{version} eq 'undef'? undef : $_->{version}), $_->{path} ] ), @rows };
      } else {
         $index->{rows}= [ sort { $a->{name} cmp $b->{name} } @rows ];
      }
   }
   return $index;
}

sub _import_sources($c) {
   my %seen;
   my @sources;
   for my $name (@{ $c->archive_tree->default_import_sources // [] }) {
      next if $seen{$name}++;
      my $tree= $c->_archive_tree_for($c->_branch_selector($name)) // next;
      push @sources, { name => $name, tree => $tree };
   }
   return \@sources;
}

# Add source_version to each row whose module is provided by an import source, and review_url
# where ArchiveTree->find_upgrades says the source has a newer distribution for that module.
# The sources are snapshots of the committed indexes, so nothing is fetched.
sub _with_source_versions($c, $rows, $sources, $authors_url) {
   my $atree= $c->archive_tree;
   my @snapshots= map +{ name => $_->{name}, by_module => $_->{index}{by_module} }, grep $_->{index}, @$sources;
   my %seen;
   my $upgrades= $atree->find_upgrades(sources => \@snapshots, dists => [ grep !$seen{$_}++, map $_->{path}, @$rows ]);
   my %review;  # { $author_path }{ $module } => upgrade
   for my $dist (@$upgrades) {
      for my $up (@{ $dist->{upgrades} }) {
         $review{$dist->{author_path}}{$_}= $up for keys %{ $up->{modules} };
      }
   }
   return map {
      my $row= $_;
      if (my $found= $atree->find_module_source($row->{name}, sources => \@snapshots)) {
         $row= { %$row, source_version => $found->{version} // 'undef' };
         if (my $up= $review{$row->{path}}{$row->{name}}) {
            my $url= _author_url($authors_url, "$row->{path}/~diff");
            $row->{review_url}= $url->query(to => $up->{author_path}, to_source => $up->{source})->to_string;
         }
      }
      $row;
   } @$rows;
}

sub _module_page($c, $index, $sources) {
   my $filter= $c->param('filter') // '';
   my $needle= lc $filter;
   my @matches= grep index(lc $_->{text}, $needle) >= 0, $index->{rows}->@*;
   my ($after, $before)= map $c->param($_), qw(after before);
   my ($start, $end)= (0, scalar @matches);
   my $max= $c->module_index_max_rows;
   if (defined $before) {
      --$end while $end && $matches[$end-1]{name} ge $before;
      $start= $end > $max? $end-$max : 0;
   } else {
      ++$start while $start < $end && defined $after && $matches[$start]{name} le $after;
      $end= $start+$max if $end > $start+$max;
   }
   my @rows= @matches[$start .. $end-1];
   if (@$sources) {
      $_->{index}= $c->_module_index($_->{tree}, 1) for @$sources;
      my $route_ns= $c->stash('cpan_ingit_route_ns');
      my $authors= $c->url_for("$route_ns.authors", author_path => '');
      @rows= $c->_with_source_versions(\@rows, $sources, $authors);
   }
   return {
      modules => \@rows,
      filter => $filter,
      tree => $c->archive_tree->tree->id,
      complete => $start == 0 && $end == @matches? JSON::PP::true : JSON::PP::false,
      next_after => @rows && $end < @matches? $rows[-1]{name} : undef,
      previous_before => @rows && $start > 0? $rows[0]{name} : undef,
   };
}

sub serve_module_list($c) {
   return undef unless $c->check_tree_exists;
   return $c->render(status => 400, json => { error => 'Supply only one of after and before' })
      if defined $c->param('after') && defined $c->param('before');
   my $index= $c->_module_index($c->archive_tree)
      or return $c->render(status => 404, json => { error => 'No package index in this tree' });
   $c->render(json => $c->_module_page($index, $c->_import_sources));
}

sub serve_index($c) {
   return undef unless $c->check_tree_exists;
   my $index= $c->_module_index($c->archive_tree)
      or return $c->render(status => 404, text => 'No package index in this tree');
   my $atree= $c->archive_tree;
   my $origin= $atree->branch;
   $origin //= $c->tree_name? $c->_tree_object($c->cpan_repo, $c->tree_name) : undef;
   (undef, $origin)= $c->cpan_repo->lookup_tree($atree->name) unless $origin;
   $origin= $origin->target while $origin && $origin->isa('Git::Raw::Tag');
   my $commit= !$origin? undef
      : $origin->isa('Git::Raw::Commit')? $origin : $origin->peel('commit');
   my $route_ns= $c->stash('cpan_ingit_route_ns');
   my $sources= $c->_import_sources;
   my $module_page= $c->_module_page($index, $sources);
   for my $source (@$sources) {
      my $url= $c->tree_name? $c->_branch_index_url($source->{name}) : $source->{tree}->canonical_url;
      $source->{url}= $url if defined $url && "$url" =~ m{\A(?:/(?!/)|https?://)}i;
   }
   $c->render(inline => $c->_share_dir->child('archive_tree_index.html.ep')->slurp('UTF-8'), handler => 'ep', format => 'html',
      module_page => $module_page, index_updated => $index->{updated}, sources => $sources,
      show_source_versions => !!@{ $atree->default_import_sources // [] },
      commit_date => $commit? gmtime($commit->time)->strftime('%a, %d %b %Y %H:%M:%S GMT') : undef,
      tree_label => $atree->name,
      json_url => $c->url_for("$route_ns.modules")->path->trailing_slash(1),
      script_url => $c->url_for("$route_ns.assets", asset => 'archive_tree_index.js'),
      cve_script_url => $c->url_for("$route_ns.assets", asset => 'cpan_cves.js'),
      authors_url => $c->url_for("$route_ns.authors", author_path => ''));
}

sub _author_url($base, $path) {
   my $url= $base->clone;
   push $url->path->parts->@*, split m{/}, $path;
   $url->path->trailing_slash($path =~ m{/\z}? 1 : 0);
   return $url;
}

# Split an author path at an archive filename followed by a slash.  Return the archive path
# and the path within the distribution (which may be empty)
sub _split_dist_member_path($path) {
   my @parts= split m{/}, $path, -1;
   for my $i (0 .. $#parts-1) {
      next unless CPAN::InGit::DistTree->parse_filename($parts[$i]);
      return (join('/', @parts[0..$i]), join('/', @parts[$i+1..$#parts]));
   }
   return;
}

sub _is_unsafe_path($path) {
   return $path =~ m{[\\:\x00-\x1f\x7f]} || !!grep { $_ eq '.' || $_ eq '..' } split m{/}, $path;
}

# Returns (author, release_name) if the author path is a release which should exist on public CPAN
sub _public_release($archive) {
   my ($author, $file)= $archive =~ m{\A[A-Z]/[A-Z]{2}/([A-Z][A-Z0-9]*)/([^/]+)\z}
      or return;
   my ($release)= CPAN::InGit::DistTree->parse_filename($file);
   return defined $release && $author ne 'LOCAL'? ($author, $release) : ();
}

sub _metacpan_url($archive, $suffix='') {
   my ($author, $release)= _public_release($archive) or return undef;
   return 'https://metacpan.org/release/'.url_escape($author).'/'.url_escape($release).$suffix;
}

# Find a distribution in the current tree, or if $source_name is given, in that import source.
# A public release is identical everywhere, so it may come from any tree that has it.
sub _find_dist($c, $archive, $source_name=undef) {
   my @trees= ($c->archive_tree);
   if (defined $source_name) {
      my $sources= $c->_import_sources;
      my ($source)= grep $_->{name} eq $source_name, @$sources
         or return undef;
      @trees= _public_release($archive)? ($source->{tree}, @trees, map $_->{tree}, @$sources)
            : ($source->{tree});
   }
   my %seen;
   for my $tree (@trees) {
      next if $seen{refaddr($tree)}++;
      my $dist= eval {
         local $Archive::Tar::WARN= 0;
         # A mirror may download the dist into the cache, but only if it is allowed to fetch
         $tree->get_dist($archive, fetch => ($tree->can('autofetch') && $tree->autofetch));
      };
      $c->log->warn("Could not read $archive in ".$tree->name.": $@") if $@;
      return $dist if $dist;
   }
   return undef;
}

sub _render_dist_bytes($c, $bytes) {
   $c->res->headers->header('X-Content-Type-Options' => 'nosniff');
   if (index($bytes, "\0") >= 0) {
      $c->res->headers->content_disposition('attachment');
      $c->res->headers->content_type('application/octet-stream');
      return $c->render(data => $bytes);
   }
   return $c->render(data => $bytes, format => 'txt');
}


sub serve_dist_member($c, $archive, $member) {
   $member =~ s{/\z}{};
   return $c->reply->not_found if _is_unsafe_path("$archive/$member");
   my $source= $c->param('source');
   return $c->reply->not_found
      if defined $source && !grep $_->{name} eq $source, @{ $c->_import_sources };
   return $c->serve_dist_diff($archive) if $member eq '~diff';

   my $dist= $c->_find_dist($archive, $source);
   if ($dist && $member eq '~changes') {
      my ($name, $blob)= $dist->changes_file;
      return $c->_render_dist_bytes($blob->content) if $blob;
   }
   elsif ($dist && $member eq '~meta') {
      $c->res->headers->header('X-CPAN-InGit-Meta-Source' => $dist->meta_source);
      return $c->render(json => $dist->meta->as_struct({ version => 2 }));
   }
   elsif ($dist && $member !~ /\A~/) {
      my $ent= $dist->get_path($member);
      return $c->_render_dist_directory($dist, $member, $source)
         if $ent && $ent->[0]->is_tree;
      # for a symlink, this shows the path it links to
      return $c->_render_dist_bytes($ent->[0]->content)
         if $ent;
   }

   if ($member eq '~changes' || (!$dist && $member !~ /\A~/)) {
      my $path= join '/', map url_escape($_), split m{/}, $member;
      my $url= _metacpan_url($archive, $member eq '~changes'? '/changes'
                                     : '/source'.(length($path)? "/$path" : ''));
      return $c->redirect_to($url) if $url;
   }
   return $c->render(status => 404, text => 'No such path in distribution');
}

sub _render_dist_directory($c, $dist, $member, $source) {
   my $route_ns= $c->stash('cpan_ingit_route_ns');
   my $plain_base= $c->url_for("$route_ns.authors", author_path => '');
   my $base= $plain_base->clone;
   $base->query(source => $source) if defined $source;
   my $archive= $dist->author_path;
   my $prefix= length($member)? "$archive/$member" : $archive;
   my $entries= $dist->list_dir($member);
   my @links= map {
      my $name= $entries->{$_}[0]->is_tree? "$_/" : $_;
      { name => $name, url => _author_url($base, "$prefix/$name") }
   } sort keys %$entries;
   my $parent= length($member)? _author_url($base, $prefix =~ s{[^/]+\z}{}r) : undef;
   my @views;
   if (!length $member) {
      push @views, { name => 'Change log', url => _author_url($base, "$archive/~changes") }
         if $dist->changes_file || _public_release($archive);
      push @views, { name => 'Metadata', url => _author_url($base, "$archive/~meta") };
      push @views, { name => 'Download', url => _author_url($plain_base, $archive) }
         unless $dist->storage eq 'upstream';
   }
   $c->render(inline => $c->_share_dir->child('dist_directory.html.ep')->slurp('UTF-8'),
      handler => 'ep', format => 'html', title => $prefix, links => \@links, parent => $parent,
      views => \@views);
}


sub serve_dist_diff($c, $archive) {
   my $to= $c->param('to');
   return $c->render(status => 400, text => "Parameter 'to' must be the author path of a distribution")
      unless defined $to && !_is_unsafe_path($to) && CPAN::InGit::DistTree->parse_filename($to);
   my ($source, $to_source)= map $c->param($_), qw( source to_source );
   return $c->reply->not_found
      if defined $to_source && !grep $_->{name} eq $to_source, @{ $c->_import_sources };
   my $from_dist= $c->_find_dist($archive, $source);
   my $to_dist= $c->_find_dist($to, $to_source);
   unless ($from_dist && $to_dist) {
      my $as= $c->param('as') // 'html';
      my $url= $as eq 'html'? _metacpan_url($to, '/changes') : undef;
      return $c->redirect_to($url) if $url;
      return $c->render(status => 404, text => 'Distribution not available: '.($from_dist? $to : $archive));
   }
   my $want_patch= ($c->param('patch') // 1)? 1 : 0;
   my $report= $from_dist->compare($to_dist,
      paths => [ grep length, @{ $c->every_param('path') } ],
      patch => $want_patch,
      hide_version_diff => ($c->param('hide_version_diff') // 1)? 1 : 0,
   );
   my $as= $c->param('as') // 'html';
   return $c->render(json => $report) if $as eq 'json';
   if ($as eq 'text') {
      $c->res->headers->header('X-Content-Type-Options' => 'nosniff');
      return $c->render(format => 'txt',
         data => Mojo::Util::encode('UTF-8', CPAN::InGit::DistTree->format_comparison($report, patch => $want_patch)));
   }
   my $route_ns= $c->stash('cpan_ingit_route_ns');
   my $base= $c->url_for("$route_ns.authors", author_path => '');
   my $browse= sub ($path, $src) {
      my $url= _author_url($base, "$path/");
      $url->query(source => $src) if defined $src;
      $url;
   };
   my $self_url= $c->req->url->clone;
   $c->render(inline => $c->_share_dir->child('dist_diff.html.ep')->slurp('UTF-8'),
      handler => 'ep', format => 'html', report => $report,
      from_url => $browse->($archive, $source), to_url => $browse->($to, $to_source),
      text_url => $self_url->clone->query({ as => 'text' }),
      json_url => $self_url->clone->query({ as => 'json' }),
   );
}


sub check_tree_exists($c) {
   unless ($c->archive_tree) {
      $c->render(text => 'Git tree does not exist', status => 404);
      return undef;
   }
   return 1;
}


sub serve_package_details($c) {
   return undef unless $c->check_tree_exists;
   my $blob= $c->archive_tree->package_details_blob;
   $c->respond_to(
      txt      => sub { $c->render(text => $blob->content) },
      'txt.gz' => sub { $c->render_gzipped($blob->content, '02packages.details.txt.gz') },
   );
}


sub serve_author_file($c) {
   return undef unless $c->check_tree_exists;
   my $author_path= $c->stash->{author_path};
   # cpanm adds extra '/' when the path name doesn't match the expected A/AU/AUTHOR format
   $author_path =~ s,//+,/,g;
   my $dist_path= $author_path;
   $dist_path .= '/' if $c->req->url->path->trailing_slash && $dist_path !~ m{/\z};
   if (my @dist= _split_dist_member_path($dist_path)) {
      return $c->serve_dist_member(@dist);
   }
   my $path= "authors/id/$author_path";
   my ($basename)= ($path =~ m,([^/]+)\z,);
   # Does the exact file exist?
   my $ent= $c->archive_tree->get_path($path);
   $c->log->debug("Path $path is ".($ent? ($ent->[0]->is_blob? 'blob ':'tree ').$ent->[0]->id : '<undef>'));
   if ($ent) {
      if ($ent->[0]->is_blob) {
         $c->res->headers->content_disposition(qq{attachment; filename="$basename"});
         $c->render(data => $ent->[0]->content);
      } else {
         $c->render(status => 403, text => 'not a file');
      }
   }
   elsif (($c->archive_tree->dist_storage($author_path) // '') eq 'unpacked') {
      my $archive= $c->archive_tree->get_distfile($author_path);
      $c->res->headers->content_type('application/gzip');
      $c->res->headers->content_disposition(qq{attachment; filename="$basename"});
      $c->render(data => $$archive);
   }
   elsif ($path =~ /(.*?)\.gz\z/
      && ($ent= $c->archive_tree->get_path($1)) && $ent->[0]->is_blob
   ) {
      $c->log->debug("Path $1 is ".$ent->[0]->id.', will gzip it');
      $c->render_gzipped($ent->[0]->content, $basename);
   }
   else {
      $c->render(status => 404, text => 'No such path in branch');
   }
}


sub render_gzipped($c, $data, $filename='') {
   my $gzipped;
   gzip \$data => \$gzipped
     or return $c->reply->exception("gzip failed: $GzipError");
   $c->res->headers->content_type('application/gzip');
   $c->res->headers->content_disposition(qq{attachment; filename="$filename"})
      if length $filename;
   return $c->render(data => $gzipped);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::Server - A Mojolicious::Controller that serves the ArchiveTrees from a git repo

=head1 DESCRIPTION

This controller serves paths that can be used directly as a CPAN Mirror by tools like 'cpanm'.
By default, it serves all branches, but you can also configure it to serve only a single branch.
It serves content directly from the Git repo and does not need a working directory checked out.

=head1 ATTRIBUTES

=head2 cpan_repo

Reference to the CPAN::InGit object from which files will be served

=head2 archive_tree

Reference to an L<ArchvieTree|CPAN::InGit::ArchvieTree> object.  If set, the controller
will serve only the tree of this branch from whatever path it was rooted at.  If not set,
this attribute will be lazy-built from attribute C<tree_name> and cached in C<tree_cache>.
The lazy-building of this attribute may return C<undef>, and should be checked I<before>
dispatching to an action.

=head2 tree_name

Explicit selector containing two path components: C<~branch/feature~demo>,
C<~tag/v1.0>, or C<~commit/OBJECT_ID>. Slashes in ref names are encoded as C<~>.

=head2 tree_cache

A hashref storing a cache of ArchiveTree objects.  This needs to be supplied in the stash if
you are loading branches by name at runtime, or else it will be
creating an ArchiveTree object on every request.

=head2 branch_head_only

If true, this prevents serving files from a Git::Raw tree which is not the HEAD of a branch.
By default, any Git sha-1, tag, or branch name may be used so long as it references a tree that
meets the requirements for an ArchiveTree.  Restricting these to branches-only can help ensure
that a malicious user can't pollute the cache and create excessive server load by touching every
tree that ever existed.

=head2 index_branches

If true, list the available local CPAN archive branches on the repository index.
Disabled by default; only applies when serving multiple trees.

=head2 module_index_max_rows

Set this to the maximum number of rows to return from the JSON endpoint that searches modules,
used by the per-tree index page.

=head1 METHODS

=head2 serve_repo_index

Serve the repository landing page.  Local branches containing CPAN configuration
and a package index are listed only when C<index_branches> is enabled in the stash.

=head2 serve_index

Serve an HTML index for a CPAN tree, including its commit date, package index date,
and the first 5000 matching modules.  When import sources are configured, show
the newest version of each module in their committed package indexes, and where a
source has a newer distribution for the module (as decided by
L<CPAN::InGit::ArchiveTree/find_upgrades>, the same rule C<cpangit-audit> uses) link
the version to a L<comparison|/serve_dist_diff> of the two distributions.
In single-tree mounts, source branches
with a canonical web URL link to that URL.

=head2 serve_module_list

Serve C<modules/> as JSON.  C<filter> is a case-insensitive literal substring matched
against the entire original 02packages row (module, version, and distribution path).
C<after> and C<before> are exclusive module-name boundaries; supply at most one.
Rows are sorted by module name, with at most 500 returned per request.

The response contains C<modules> (objects with C<name>, C<version>, C<path>, and
C<text>, plus C<source_version> and C<review_url> where applicable),
the applied C<filter>, the Git C<tree> ID, and C<next_after> and
C<previous_before> cursors (null at either end).  C<complete> is true only when
this response includes every row matching the filter, including rows outside
the requested boundary.  A client may then narrow that filter locally.

=head2 serve_dist_member

Serve a path within a distribution; a directory listing, a file, or one of the special
names C<~changes>, C<~meta>, or C<~diff>.  If the distribution is a public CPAN release
which can't be found (or has no change log), this redirects to the equivalent page of
metacpan.org.

=head2 serve_dist_diff

Compare the distribution named by the URL with another distribution, for reviewing an
upgrade (or downgrade, or local patch).  Query parameters:

=over

=item to

Required.  The author path of the distribution to compare with.

=item source

Optional name of an import source in which to look for the distribution of the URL.

=item to_source

Optional name of an import source in which to look for the C<to> distribution.

=item path

Optional, and may be repeated.  Limit the file comparison to these paths.

=item patch

Set to C<0> to omit the patches from the response.

=item hide_version_diff

Set to C<0> to show the hunks which only change the version number.
See L<CPAN::InGit::DistTree/compare>.

=item as

C<json> returns the structure described in L<CPAN::InGit::DistTree/compare>.
C<text> returns the plain-text rendering of L<CPAN::InGit::DistTree/format_comparison>.
The default is an HTML page.

=back

If either distribution can't be found, this redirects to the change log of the C<to>
distribution on metacpan.org when that is a public release, and otherwise returns 404.

=head2 check_tree_exists

This checks that the L</tree_name> could be successfully resolved to a L</archive_tree>.
It returns true, or sets a 404 error and returns undef, and can be used as C<< ->under(\&check_tree_exists) >>.

=head2 serve_package_details

Serve C<< modules/02packages.details.txt[.gz] >>.

=head2 serve_author_file

Serve all files under C<< authors/id/... >>.  (All files in that path of the git branch are considered public)
This performs automatic creation of .tar.gz files if a directory and matching .meta file exist,
allowing distributions to be unpacked within the git repo, but served as .tar.gz files.
A trailing slash after an archive filename browses its contents, and a path after the slash
is handled by L</serve_dist_member>.

=head2 render_gzipped

Serve content after gzipping it and setting the content type to C<< application/gzip >>.

=head1 ROUTES

=head2 Cpan Mirror Paths

A functioning CPAN mirror requires a file C<< /modules/02packages.details.txt.gz >> which lists
the full contents of the latest version of every module.  That file also lists the author paths
for each module, which are relative to C<< /authors/id/ >>

In CPAN::InGit, C<< /modules/02packages.details.txt >> is stored uncompressed, and
gzipped as it is served.  Each author dist is stored as a .tar.gz file and a metadata file with
extension .meta and may also optionally be unpacked at a directory of the same name minus the
.tar.gz extension.  A special author "LOCAL" is used for custom overrides of upstream packages.

Summary:

  /                                                 # browsable tree index
  /modules/?filter=TEXT&after=MODULE                # filtered module list
  /modules/02packages.details.txt                   # index of the mirror
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz     # copy of upstream
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.meta       # extracted metadata
  /authors/id/L/LO/LOCAL/Crypt-DES-2.07_01/...      # untarred customized dist
  /authors/id/L/LO/LOCAL/Crypt-DES-2.07_01.meta     # untarred customized dist's metadata

=head2 Distribution Contents

A path that continues beyond the file name of a distribution archive refers to the contents
of that distribution.  The files of the distribution are found directly beneath the archive
name (the customary wrapper directory of the archive is not part of the path) and names
beginning with C<~> are special views of the distribution:

  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz/            # directory listing
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz/lib/        # directory listing
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz/DES.pm      # one file
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz/~changes    # the change log, whatever its name
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz/~meta       # CPAN Meta (version 2) as JSON
  /authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz/~diff?to=D/DP/DPARIS/Crypt-DES-2.08.tar.gz

All of these accept a query parameter C<source> naming one of the tree's
C<default_import_sources>, to look for the distribution in that tree instead.  See
L</serve_dist_diff> for the parameters of C<~diff>.

=head2 mount

  my $route= app->routes->any('/pan');
  my $repo= CPAN::InGit->new(git_repo => '/path/to/.git');
  CPAN::InGit::Server->mount($route, $repo, app => app, %options);
  # %options:
  #   archive_tree => $ArchiveTree_obj,
  #   tree_cache => $branch_cache,
  #   index_branches => 1, # optionally list local CPAN archive branches
  #   branch_head_only => 1, # only serve actual branch HEADs

This class method sets up the routes for serving the mirror under a provided route.
C<$route> is the route under which you want to serve the 'PAN.
The C<app> option supplies the owning Mojolicious application and is required for
multi-tree mounts, to install the C<before_routes> path-rewriting hook.

If you specify 'archive_tree', that `PAN will be directly mounted at the route.
Otherwise, all trees (or just branches if you use option C<branch_head_only>) will be mounted
as:

  /                                                 # repository index
  /~static/...                                      # static files served publicly
  /~branch/:branch_name/*tree                       # branch, with '/' replaced by '~'
  /~tag/:tag_name/*tree                             # tag, with '/' replaced by '~'
  /~commit/:sha1/*tree                              # SHA-1 Hex commit ID
  /*name/*tree                                      # branch, else tag, else commit

The route's root serves a repository index; C<index_branches> enables
branch links on that page and defaults to false.

Browsing and comparing the contents of distributions unpacks each archive once
into L<CPAN::InGit/dist_cache_repo>.

Files in C<share/public> are served verbatim under C<~static/> within the mount,
using Mojo's static file handler.

The C<~branch>, C<~tag>, and C<~commit> prefixes are followed by a single path component that
unambiguously represents a tree; branch and tag names containing '/' have that character
replaced by '~'.  In the last form, path components are consumed from the URL in sequence until
it matches a branch or tag or SHA1, which is convenient but can be ambiguous.  For example,
if a tag named C<issue> exists and a branch named C<issue/123> exists, a url for
C<< issue/123/modules >> resolves to the path C<< 123/modules >> within tag "issue", and does
not find the branch.  Most users won't have overlapping branches and tags, though, so these
URLs are more convenient.

=head1 VERSION

version 0.007

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
