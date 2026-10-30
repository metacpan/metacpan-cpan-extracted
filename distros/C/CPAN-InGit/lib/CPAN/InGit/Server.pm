package CPAN::InGit::Server;
our $VERSION = '0.006'; # VERSION
# ABSTRACT: A Mojolicious::Controller that serves the ArchiveTrees from a git repo


use Carp;
use Scalar::Util 'refaddr', 'blessed';
use JSON::PP;
use Time::Piece;
use Log::Any '$log';
use Archive::Tar;
use IO::Compress::Gzip qw( gzip $GzipError );
use CPAN::InGit;
use File::ShareDir ();
use Mojo::File 'path';
use Mojolicious::Static;
use Mojo::Base 'Mojolicious::Controller';
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
   $c->stash->{archive_tree} //= do {
      my $tree_name= $c->tree_name;
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
      $atree;
   };
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
   # Ensure there is a cache if serving all branches
   $options{branch_cache} //= $class->_new_cache
      unless defined $atree;
   # This function could be called multiple times to mount various repos at different paths,
   # so each instance needs a different route namespace.
   # The route_ns is added as a stash attribute and used by actions when generating URLs.
   my $route_ns= 'cpan_ingit_'.++$base_route->root->{_cpan_ingit_mount_count};
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
      my $route_ns= $c->stash('cpan_ingit_route_ns');
      for my $branch (sort { $a->shorthand cmp $b->shorthand } $c->cpan_repo->git_repo->branches('local')) {
         my $tree= $branch->peel('tree');
         next unless $tree->entry_bypath('cpan_ingit.json')
            && $tree->entry_bypath('modules/02packages.details.txt');
         my $name= $branch->shorthand;
         push @branches, { name => $name, url => $c->url_for("$route_ns.index", tree_name => '~branch/'.($name =~ tr{/}{~}r))->path->trailing_slash(1) };
      }
   }
   $c->render(inline => $c->_share_dir->child('repo_index.html.ep')->slurp('UTF-8'), handler => 'ep', format => 'html',
      index_branches => $index_branches, branches => \@branches);
}


sub _module_index($c) {
   my $atree= $c->archive_tree;
   my $blob= $atree->package_details_blob;
   return undef unless $blob;
   my $index= $atree->{_server_module_index};
   unless ($index && $index->{blob_id} eq $blob->id) {
      my ($headers, $body)= split /\r?\n\r?\n/, $blob->content, 2;
      my ($updated)= $headers =~ /^Last-Updated:\s*([^\r\n]*)/m;
      my @rows;
      for my $line (split /\r?\n/, $body // '') {
         next unless $line =~ /^(\S+)\s+(\S+)\s+(\S+)\s*$/;
         push @rows, { name => $1, version => $2, path => $3, text => $line };
      }
      @rows= sort { $a->{name} cmp $b->{name} } @rows;
      $index= $atree->{_server_module_index}= { blob_id => $blob->id, updated => $updated, rows => \@rows };
   }
   return $index;
}

sub _module_page($c, $index) {
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
   my $index= $c->_module_index
      or return $c->render(status => 404, json => { error => 'No package index in this tree' });
   $c->render(json => $c->_module_page($index));
}

sub serve_index($c) {
   return undef unless $c->check_tree_exists;
   my $index= $c->_module_index
      or return $c->render(status => 404, text => 'No package index in this tree');
   my $atree= $c->archive_tree;
   my $origin= $atree->branch;
   $origin //= $c->tree_name? $c->_tree_object($c->cpan_repo, $c->tree_name) : undef;
   (undef, $origin)= $c->cpan_repo->lookup_tree($atree->name) unless $origin;
   $origin= $origin->target while $origin && $origin->isa('Git::Raw::Tag');
   my $commit= !$origin? undef
      : $origin->isa('Git::Raw::Commit')? $origin : $origin->peel('commit');
   my $route_ns= $c->stash('cpan_ingit_route_ns');
   $c->render(inline => $c->_share_dir->child('archive_tree_index.html.ep')->slurp('UTF-8'), handler => 'ep', format => 'html',
      module_page => $c->_module_page($index), index_updated => $index->{updated},
      commit_date => $commit? gmtime($commit->time)->strftime('%a, %d %b %Y %H:%M:%S GMT') : undef,
      tree_label => $atree->name,
      json_url => $c->url_for("$route_ns.modules")->path->trailing_slash(1),
      script_url => $c->url_for("$route_ns.assets", asset => 'archive_tree_index.js'),
      cve_script_url => $c->url_for("$route_ns.assets", asset => 'cpan_cves.js'),
      authors_url => $c->url_for("$route_ns.authors", author_path => ''));
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
   my $path= 'authors/id/'.$c->stash->{author_path};
   # cpanm adds extra '/' when the path name doesn't match the expected A/AU/AUTHOR format
   $path =~ s,//+,/,g;
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
   elsif ($path =~ /(.*?)\.gz\z/
      && ($ent= $c->archive_tree->get_path($1)) && $ent->[0]->is_blob
   ) {
      $c->log->debug("Path $1 is ".$ent->[0]->id.', will gzip it');
      $c->render_gzipped($ent->[0]->content, $basename);
   }
   elsif ($path =~ /(.*?)\.tar\.gz\z/
      # Don't auto-tar trees that don't look like distributions
      && ($ent= $c->archive_tree->get_path("$1.meta")) && $ent->[0]->is_blob
      && ($ent= $c->archive_tree->get_path($1)) && $ent->[0]->is_tree
   ) {
      $c->log->debug("Path $1 is ".$ent->[0]->id.', will tar+gzip it');
      my $tar= Archive::Tar->new;
      $c->cpan_repo->add_git_tree_to_tar($tar, substr($basename, 0, -7), $ent->[0]);
      $c->render_gzipped($tar->write, $basename);
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
and the first 5000 matching modules.

=head2 serve_module_list

Serve C<modules/> as JSON.  C<filter> is a case-insensitive literal substring matched
against the entire original 02packages row (module, version, and distribution path).
C<after> and C<before> are exclusive module-name boundaries; supply at most one.
Rows are sorted by module name, with at most 500 returned per request.

The response contains C<modules> (objects with C<name>, C<version>, C<path>, and
C<text>), the applied C<filter>, the Git C<tree> ID, and C<next_after> and
C<previous_before> cursors (null at either end).  C<complete> is true only when
this response includes every row matching the filter, including rows outside
the requested boundary.  A client may then narrow that filter locally.

=head2 check_tree_exists

This checks that the L</tree_name> could be successfully resolved to a L</archive_tree>.
It returns true, or sets a 404 error and returns undef, and can be used as C<< ->under(\&check_tree_exists) >>.

=head2 serve_package_details

Serve C<< modules/02packages.details.txt[.gz] >>.

=head2 serve_author_file

Serve all files under C<< authors/id/... >>.  (All files in that path of the git branch are considered public)
This performs automatic creation of .tar.gz files if a directory and matching .meta file exist,
allowing distributions to be unpacked within the git repo, but served as .tar.gz files.

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

version 0.006

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
