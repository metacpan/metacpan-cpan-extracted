package CPAN::InGit::ArchiveTree;
our $VERSION = '0.007'; # VERSION
# ABSTRACT: An object managing a CPAN file structure in a Git Tree


use Carp;
use Scalar::Util 'blessed';
use POSIX 'strftime';
use Archive::Tar;
use CPAN::Meta 2.150010;
use IO::Compress::Gzip qw( gzip $GzipError );
use CPAN::InGit::DistTree;
use JSON::PP;
use Time::Piece;
use Log::Any '$log';
use Moo;
use version ();
use v5.36;

extends 'CPAN::InGit::MutableTree';


sub BUILD($self, $args, @) {
   $self->load_config if $self->config_blob;
   $self->name($self->branch? $self->branch->shorthand : '(anonymous)')
      unless defined $self->name;
}

has name   => ( is => 'rw' );
has config => ( is => 'rw' );

sub config_blob($self) {
   my $ent= $self->get_path('cpan_ingit.json')
      or return undef;
   return $ent->[0]->is_blob? $ent->[0] : undef;
}


sub load_config($self) {
   my $cfg_blob= $self->config_blob
      or die "Missing '/cpan_ingit.json'";
   my $attrs= JSON::PP->new->utf8->relaxed->decode($cfg_blob->content);
   ref $attrs eq 'HASH' or croak "Configuration file does not contain an object?".$cfg_blob->content;
   $self->{config}= $attrs;
   $self->_unpack_config($self->{config});
   $attrs;
}

sub _unpack_config($self, $config) {
   for (qw( default_import_sources corelist_perl_version canonical_url )) {
      $self->$_($config->{$_}) if defined $config->{$_};
   }
}

sub _pack_config($self, $config) {
   for (qw( default_import_sources corelist_perl_version canonical_url )) {
      my $val= $self->$_;
      $val= "$val" if ref $val eq 'version';
      $config->{$_}= $val;
   }
}

sub write_config($self) {
   my $config= $self->config // {};
   $self->_pack_config($config);
   my $json= JSON::PP->new->utf8->canonical->pretty->encode($config);
   $self->set_path('cpan_ingit.json', \$json)
      unless $self->config_blob && $self->config_blob->content eq $json;
   $self;
}


has canonical_url          => ( is => 'rw' );
has default_import_sources => ( is => 'rw' );
has corelist_perl_version  => ( is => 'rw', default => '5.008009' );


sub package_details_blob($self) {
   my $ent= $self->get_path('modules/02packages.details.txt')
      or return undef;
   return $ent->[0]->is_blob? $ent->[0] : undef;
}

has package_details => ( is => 'rw', lazy => 1, builder => 1, clearer => 1 );
sub _build_package_details($self) {
   my $blob= $self->package_details_blob;
   return $blob? $self->parse_package_details($blob->content)
               : { by_module => {}, by_dist => {} };
}


sub parse_package_details($self, $content) {
   my %attrs;
   while ($content =~ /\G([^:\n]+):\s+(.*)\n/gc) {
      $attrs{$1}= $2;
   }
   $content =~ /\G\n/gc or croak "missing blank line after headers";
   my %by_mod;
   my %by_dist;
   while ($content =~ /\G(\S+)\s+(\S+)\s+(\S+)\n/gc) {
      my $row= [ $1, ($2 eq 'undef'? undef : $2), $3 ];
      $by_mod{$1}= $row;
      push @{$by_dist{$3}}, $row;
   }
   pos $content == length $content
      or croak "Parse error at '".substr($content, pos($content), 10)."'";
   my $timestamp = $attrs{'Last-Updated'}? Time::Piece->strptime($attrs{'Last-Updated'}, "%a, %d %b %Y %H:%M:%S GMT")
                 : undef; # TODO: fall back to date from branch commit
   return {
      last_update => $timestamp,
      by_module   => \%by_mod,
      by_dist     => \%by_dist,
   };
}


sub write_package_details($self) {
   my $content= $self->_format_package_details($self->package_details);
   $self->set_path('modules/02packages.details.txt', \$content);
}

sub _format_package_details($self, $details) {
   my $url= $self->canonical_url // 'cpan_mirror_ingit.local';
   my @mod_list= values %{$details->{by_module}};
   my $line_count= @mod_list;
   my $date= strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime);
   my $content= <<~END;
      File:         02packages.details.txt
      URL:          $url
      Description:  Package names found in directory \$CPAN/authors/id/
      Columns:      package name, version, path
      Intended-For: Automated fetch routines, namespace documentation.
      Written-By:   PAUSE version 1.005
      Line-Count:   $line_count
      Last-Updated: $date

      END
   # List can be huge, so try to be efficient about stringifying it
   @mod_list= sort { fc $a->[0] cmp fc $b->[0] } @mod_list;
   my @lines;
   for (@mod_list) {
      push @lines, sprintf("%s %s  %s\n", $_->[0], $_->[1] // 'undef', $_->[2]);
   }
   return join('', $content, @lines);
}


sub index_distribution($self, $author_path, $versions) {
   $self->_index_distribution($self->package_details, $author_path, $versions);
   $self->write_package_details;
}

sub _index_distribution($self, $details, $author_path, $versions) {
   my ($by_module, $by_dist)= @$details{qw( by_module by_dist )};
   my %changed= ($author_path => 1);
   for my $row (@{delete($by_dist->{$author_path}) // []}) {
      delete $by_module->{$row->[0]}
         if ($by_module->{$row->[0]} // [])->[2] && $by_module->{$row->[0]}[2] eq $author_path;
   }
   for my $name (keys %$versions) {
      $changed{$by_module->{$name}[2]}= 1 if $by_module->{$name};
      my $row= [ $name, $versions->{$name}, $author_path ];
      $by_module->{$name}= $row;
      push @{$by_dist->{$author_path}}, $row;
   }
   for my $path (keys %changed) {
      next unless $by_dist->{$path};
      @{$by_dist->{$path}}= grep { ($by_module->{$_->[0]} // 0) == $_ } @{$by_dist->{$path}};
      delete $by_dist->{$path} unless @{$by_dist->{$path}};
   }
}


sub has_module($self, $mod_name, $reqs=undef) {
   my $mod_ver= $self->get_module_version($mod_name);
   if (defined $mod_ver && defined $reqs) {
      $reqs= CPAN::Meta::Requirements->from_string_hash({ $mod_name => $reqs })
         unless ref $reqs;
      return !!$reqs->accepts_module($mod_name, $mod_ver);
   }
   return defined $mod_ver;
}

sub get_module_version($self, $mod_name) {
   if (my $current= $self->package_details->{by_module}{$mod_name}) {
      my $mod_ver= $current->[1];
      # grab the version out of the package filename?
      if (!defined $mod_ver) {
         $mod_ver= $current->[2] =~ /-([0-9]+(?:\.[0-9_]+?)*)\./? $1
                 : 0; # return 0 to differentiate from undef=nonexisting
      }
      return $mod_ver;
   } elsif ($mod_name eq 'perl') {
      return $self->corelist_perl_version;
   } else {
      return undef;
   }
}

sub get_module_dist($self, $mod_name) {
   my $by_name= $self->package_details->{by_module}{$mod_name};
   return $by_name? $by_name->[2] : undef;
}


sub _parse_version($v) { defined $v? eval { version->parse($v) } : undef }

# Normalize a list of trees or { name, by_module } into [ [ $name, \%by_module ], ... ]
sub _source_indexes($self, $sources) {
   $sources //= [ map { $self->parent->get_archive_tree($_) // () } @{ $self->default_import_sources // [] } ];
   return [ map { blessed($_)? [ $_->name, $_->package_details->{by_module} ] : [ $_->{name}, $_->{by_module} ] } @$sources ];
}

# Returns ($index_row, $parsed_version, $source_name) of the best provider of a module
sub _best_source_row($mod, $source_idx) {
   my ($best, $best_ver, $best_source);
   for (@$source_idx) {
      my $candidate= $_->[1]{$mod} or next;
      my $ver= _parse_version($candidate->[1]);
      next if $best && (!defined $ver || (defined $best_ver && $ver <= $best_ver));
      ($best, $best_ver, $best_source)= ($candidate, $ver, $_->[0]);
   }
   return ($best, $best_ver, $best_source);
}

sub find_module_source($self, $mod, %options) {
   my ($row, undef, $source)= _best_source_row($mod, $self->_source_indexes($options{sources}));
   return $row && { module => $mod, version => $row->[1], author_path => $row->[2], source => $source };
}

sub find_upgrades($self, %options) {
   my $source_idx= $self->_source_indexes($options{sources});
   my $parse= \&_parse_version;
   my $by_dist= $self->package_details->{by_dist};
   my @result;
   for my $author_path ($options{dists}? (sort grep $by_dist->{$_}, @{ $options{dists} }) : sort keys %$by_dist) {
      my (%pairs, @same, @missing);
      for my $row (@{ $by_dist->{$author_path} }) {
         my ($mod, $mod_ver)= @$row;
         my ($best, $best_ver, $best_source)= _best_source_row($mod, $source_idx);
         if (!$best) { push @missing, $mod }
         elsif ($best->[2] eq $author_path) { push @same, $mod }
         else {
            my $pair= $pairs{$best->[2]} //= { source => $best_source, modules => {}, newer_module => 0 };
            $pair->{modules}{$mod}= [ $mod_ver, $best->[1] ];
            my $cur_ver= $parse->($mod_ver);
            $pair->{newer_module}= 1 if defined $best_ver && (!defined $cur_ver || $best_ver > $cur_ver);
         }
      }
      my ($dist, $version)= CPAN::InGit::DistTree->parse_release($author_path);
      my $dist_ver= $parse->($version);
      my @upgrades;
      for my $to_path (sort keys %pairs) {
         my $pair= $pairs{$to_path};
         my ($to_dist, $to_version)= CPAN::InGit::DistTree->parse_release($to_path);
         my $to_ver= $parse->($to_version);
         my $same_name= defined $dist && defined $to_dist && $dist eq $to_dist;
         my $newer= $same_name && defined $dist_ver && defined $to_ver? $to_ver > $dist_ver
                  : $pair->{newer_module};
         next unless $newer;
         push @upgrades, {
            author_path => $to_path, dist => $to_dist, version => $to_version,
            source => $pair->{source}, kind => ($same_name? 'upgrade' : 'moved'),
            modules => $pair->{modules},
         };
      }
      next unless @upgrades;
      push @result, {
         author_path => $author_path, dist => $dist, version => $version,
         upgrades => \@upgrades,
         (@same?    ( left_behind   => [ sort @same ] ) : ()),
         (@missing? ( not_in_source => [ sort @missing ] ) : ()),
      };
   }
   return \@result;
}


sub meta_path_for_dist($self, $author_path) {
   # Replace the archive extension with '.meta'.
   my (undef, $ext)= CPAN::InGit::DistTree->parse_filename($author_path);
   $author_path= substr($author_path, 0, -1 - length $ext) if defined $ext;
   return "authors/id/$author_path.meta";
}


sub import_dist($self, $peer, $author_path, %options) {
   my $dist_path= "authors/id/$author_path";
   my $distfile_ent= $peer->get_path($dist_path);
   if (!$distfile_ent && ($peer->dist_storage($author_path) // '') eq 'unpacked') {
      my $bytes= $peer->get_distfile($author_path);
      $distfile_ent= [ Git::Raw::Blob->create($self->git_repo, $$bytes), 0100644 ];
   }
   croak "Import source branch '".$peer->name."' does not contain $dist_path" unless $distfile_ent;
   $log->info("Importing $author_path from ".$peer->name." to ".$self->name);
   my $existing_ent= $self->get_path($dist_path);
   # If exists, must be same gitobj as before or this is an error
   if ($existing_ent) {
      croak "$dist_path already exists with different content"
         unless $existing_ent->[0]->id eq $distfile_ent->[0]->id;
   }
   my $modules_registered= $peer->package_details->{by_dist}{$author_path};
   my %versions= map { $_->[0] => $_->[1] } @{ $modules_registered // [] };
   # Inspection of the archive is advisory; an unreadable archive can still be copied.
   my $dist= eval {
      local $Archive::Tar::WARN= 0;
      $peer->get_dist($author_path);
   };
   if ($dist) {
      my @unindexed= sort grep !exists $versions{$_}, keys %{ $dist->provides };
      $log->warn("Packages claimed by $author_path but missing from the index for this distribution in "
         .$peer->name.': '.join(', ', @unindexed)) if @unindexed;
   }
   $self->set_path($dist_path, $distfile_ent->[0], mode => $distfile_ent->[1]);
   if ($modules_registered) {
      $self->index_distribution($author_path, \%versions);
   }
   my $meta_path= $self->meta_path_for_dist($author_path);
   my $meta_ent= $peer->get_path($meta_path);
   if ($meta_ent) {
      $self->set_path($meta_path, $meta_ent->[0], mode => $meta_ent->[1]);
   } elsif ($dist && $dist->meta_source ne 'synthesized') {
      my $json= $dist->meta->as_string({ version => 2 });
      $self->set_path($meta_path, \$json);
   } else {
      $log->warn("No META for $author_path");
   }
   return $self;
}


sub dist_storage($self, $author_path) {
   my $entry= $self->SUPER::get_path("authors/id/$author_path");
   return 'archive' if $entry && $entry->[0]->is_blob;
   return $self->_unpacked_dist_dir($author_path)? 'unpacked' : undef;
}

# Return the Git::Raw::Tree for a distribution stored as a directory, having the name of
# a .tar.gz author path without the extension, and a metadata sidecar.
sub _unpacked_dist_dir($self, $author_path) {
   return undef unless $author_path =~ /\.tar\.gz\z/;
   my $meta= $self->SUPER::get_path($self->meta_path_for_dist($author_path));
   return undef unless $meta && $meta->[0]->is_blob;
   my $dir= $self->SUPER::get_path('authors/id/'.substr($author_path, 0, -7));
   return $dir && $dir->[0]->is_tree? $dir->[0] : undef;
}


sub get_dist($self, $author_path, %options) {
   my ($name)= CPAN::InGit::DistTree->parse_filename($author_path)
      or return undef;
   my $repo= $self->parent;
   my ($tree, $storage);
   my $entry= $self->SUPER::get_path("authors/id/$author_path");
   if ($entry && $entry->[0]->is_blob) {
      my $blob= $entry->[0];
      $storage= 'archive';
      $tree= $repo->cached_dist_tree('blob/'.$blob->id, sub {
         $log->debug("Unpacking $author_path into dist cache");
         CPAN::InGit::DistTree->new_from_archive(
            parent => $repo, filename => $author_path, data => \($blob->content)
         )->tree;
      });
   } elsif ($tree= $self->_unpacked_dist_dir($author_path)) {
      $storage= 'unpacked';
   } else {
      return undef;
   }
   return CPAN::InGit::DistTree->new(
      parent => $repo, tree => $tree, name => $name,
      author_path => $author_path, storage => $storage,
   );
}


sub get_distfile($self, $author_path) {
   my $entry= $self->SUPER::get_path("authors/id/$author_path");
   return \$entry->[0]->content if $entry && $entry->[0]->is_blob;
   my $tree= $self->_unpacked_dist_dir($author_path) // return undef;
   my ($name)= $author_path =~ m{([^/]+)\.tar\.gz\z};
   my $tar= Archive::Tar->new;
   $self->parent->add_git_tree_to_tar($tar, $name, $tree);
   my $raw= $tar->write;
   gzip \$raw => \my $compressed, Time => 0 or croak "gzip failed: $GzipError";
   return \$compressed;
}


sub localize_module($self, $package, %options) {
   my @sources= ($self, @{ $options{sources} // $self->default_import_sources // [] });
   for my $source (@sources) {
      $source= $self->parent->get_archive_tree($source)
         // croak "No such archive tree $source" unless ref $source;
      my $path= $source->get_module_dist($package) // next;
      my $bytes= $source->get_distfile($path) // next;
      my $rows= $source->package_details->{by_dist}{$path};
      return $self->add_local_dist($path, $bytes,
         versions => { map { $_->[0] => $_->[1] } @$rows });
   }
   croak "No distribution found for $package in ".$self->name." or its import sources";
}


sub add_local_dist($self, $filename, $bytes, %options) {
   my $dist= CPAN::InGit::DistTree->new_from_archive(
      parent => $self->parent, filename => $filename, data => $bytes
   );
   # The files might get written to a working directory
   $dist->check_symlinks;
   my $name= $dist->name;
   my $meta= $dist->meta->as_struct({ version => 2 });
   my $provides= $meta->{provides}= { %{ $dist->provides } };
   my $versions= $options{versions} // { map { $_ => $provides->{$_}{version} } keys %$provides };
   for my $pkg (keys %$versions) {
      croak "Invalid package index entry in $filename"
         if $pkg !~ /\A\S+\z/ || (defined $versions->{$pkg} && $versions->{$pkg} !~ /\A\S+\z/);
   }

   my $author_path= "L/LO/LOCAL/$name.tar.gz";
   my $root= "authors/id/L/LO/LOCAL/$name";
   my $meta_path= $self->meta_path_for_dist($author_path);
   $self->check_new_paths($root, "authors/id/$author_path", $meta_path);

   for my $pkg (keys %$provides) {
      if (!exists $versions->{$pkg}) {
         delete $provides->{$pkg};
      } else {
         $provides->{$pkg}= { %{ $provides->{$pkg} } };
         if (defined $versions->{$pkg}) {
            $provides->{$pkg}{version}= $versions->{$pkg};
         } else {
            delete $provides->{$pkg}{version};
         }
      }
   }
   my $json= CPAN::Meta->new($meta)->as_string({ version => 2 });
   $self->package_details; # Read the current index before adding any files.
   $log->info("Unpacking $filename as $author_path");
   $self->set_path($root, $dist->files);
   $self->set_path($meta_path, \$json);
   $self->index_distribution($author_path, $versions);
   return $author_path;
}


sub get_dist_meta($self, $author_path, %options) {
   my $meta_path= $self->meta_path_for_dist($author_path);
   my $meta_ent= $self->get_path($meta_path);
   return CPAN::Meta->load_string($meta_ent->[0]->content)
      if $meta_ent;
   my $dist= eval {
      local $Archive::Tar::WARN= 0;
      $self->get_dist($author_path);
   };
   return $dist? $dist->meta : undef;
}


sub _filter_prereqs($self, $reqs, $corelist={}, $log_prefix='') {
   for my $mod (sort $reqs->required_modules) {
      my $req_version= $reqs->requirements_for_module($mod);
      my $have_ver= $self->get_module_version($mod);
      # Is this requirement already in the tree?
      if (defined $have_ver && $reqs->accepts_module($mod, $have_ver)) {
         $log->debugf($log_prefix.'(requirement %s %s already satisfied by %s from %s)',
            $mod, $req_version, $have_ver,
            ($mod eq 'perl'? 'corelist_perl_version' : $self->get_module_dist($mod)))
            if $log->is_info;
         $reqs->clear_requirement($mod);
      }
      # Is the requirement satisfied by a core perl module in the version of perl
      # the app will be running under?
      elsif (defined $corelist->{$mod} && $reqs->accepts_module($mod, $corelist->{$mod})) {
         $log->debugf($log_prefix.'(requirement %s %s satisfied by corelist)', $mod, $req_version);
         $reqs->clear_requirement($mod);
      }
   }
   return $reqs;
}

# merges new requirements into existing, and returns a list of anything that changed
sub _merge_prereqs($self, $reqs, $new_reqs) {
   my $before= $reqs->as_string_hash;
   $reqs->add_requirements($new_reqs);
   my $after= $reqs->as_string_hash;
   my @changed;
   for my $mod (sort $new_reqs->required_modules) {
      if (($before->{$mod} // '') ne ($after->{$mod} // 0)) {
         push @changed, $mod;
         $log->infof('  requires %s%s', $mod, $after->{$mod}? " $after->{$mod}" : '');
      }
   }
   return @changed;
}

sub import_modules($self, $reqs, %options) {
   my %imported_dists;

   # Build list of source trees
   my $sources= $options{sources} // $self->default_import_sources;
   $sources && @$sources
      or croak "No import sources specified";
   # coerce every source name to an ArchiveTree object
   my @autocommit;
   for (@$sources) {
      unless (ref $_ and $_->can('package_details')) {
         my $t= $self->parent->get_archive_tree($_)
            or croak "No such archive tree $_";
         # If we've created new objects for MirrorTree and the MirrorTree has autofetch
         # enabled, then we also need to commit those changes before returning.
         push @autocommit, $t if $t->can('autofetch') && $t->autofetch;
         $_= $t;
      }
   }

   # Coerce the argument to a Requirements object
   require CPAN::Meta::Requirements;
   my $prereq_phases= [qw( configure build runtime test )];
   my $prereq_types=  [qw( requires )];
   my $log_recommends= !grep $_ eq 'recommends', @$prereq_types;
   my $recommended= CPAN::Meta::Requirements->new;
   # coerce the requirements into a CPAN::Meta::Requirements object
   $reqs= ref $reqs eq 'HASH'? CPAN::Meta::Requirements->from_string_hash($reqs)
        : blessed($reqs) && $reqs->isa('CPAN::Meta::Requirements')? $reqs
        : blessed($reqs) && $reqs->isa('CPAN::Meta::Prereqs')? $reqs->merged_requirements($prereq_phases, $prereq_types)
        : croak "Expected CPAN::Meta::Requirements object, ::Prereqs object, or HASH ref";

   # Determine what module versions were available for the app's version of perl.
   require Module::CoreList;
   my $perl_v= $options{corelist_perl_version} // $self->corelist_perl_version;
   $perl_v= version->parse($perl_v)->numify;
   my $corelist= Module::CoreList::find_version($perl_v)
      or carp "No corelist for $perl_v";

   # Filter out the prereqs we already have, or which are in the corelist
   $log->tracef('todo reqs: %s', $reqs->as_string_hash);
   $self->_filter_prereqs($reqs, $corelist);
   my @initial_list= $reqs->required_modules;
   my @todo= @initial_list;
   while (@todo) {
      my $mod= shift @todo;
      my $req_version= $reqs->requirements_for_module($mod);
      $log->infof('Add %s %s', $mod, $req_version);
      # Walk through the list of import sources looking for a version that works
      my ($author_path, $prereqs);
      for my $peer (@$sources) {
         my $peer_ver= $peer->get_module_version($mod);
         if (!defined $peer_ver) {
            $log->debugf('  branch %s does not have module %s', $peer->name, $mod);
         }
         elsif (!$reqs->accepts_module($mod, $peer_ver)) {
            $log->debugf('  branch %s module %s version %s does not match %s', $peer->name, $mod, $peer_ver, $req_version);
         }
         else {
            $log->debugf('  branch %s has %s %s, matching %s', $peer->name, $mod, $peer_ver, $req_version);
            $author_path= $peer->get_module_dist($mod);
            $self->import_dist($peer, $author_path);
            my $meta= $self->get_dist_meta($author_path);
            $prereqs= $meta->effective_prereqs if $meta;
            $imported_dists{$author_path}= $peer;
            last;
         }
      }
      croak("No import_sources branch had module $mod with version $req_version")
         unless length $author_path;
      # Push things into the TODO list if they aren't already in %$reqs or if they have a higher
      # version requirement.
      if ($prereqs) {
         my $dist_reqs= $prereqs->merged_requirements($prereq_phases, $prereq_types);
         $log->infof('Dist %s:', $author_path);
         my $n= $#todo;
         push @todo, $self->_merge_prereqs($reqs, $self->_filter_prereqs($dist_reqs, $corelist, '  '));
         $log->infof('  (no additional reqs)') if $#todo == $n;
         # Collect recommendations
         if ($log_recommends) {
            my $dist_recommends= $prereqs->merged_requirements(['runtime'], ['recommends']);
            $self->_filter_prereqs($dist_recommends, $corelist);
            my @list= sort $dist_recommends->required_modules;
            $log->noticef('Dist %s recommends %s', $mod, [ sort @list ])
               if @list;
            $recommended->add_requirements($dist_recommends);
         }
      }
   }
   if ($log_recommends) {
      if (my @list= sort $recommended->required_modules) {
         $log->notice('Full list of recommended modules:');
         $log->noticef('  %s %s', $_, $recommended->requirements_for_module($_))
            for @list;
      }
   }
   # If any sources are 'autofetch' and caller didn't supply the MirrorTree object,
   # commit the changes before returning.
   for my $mirror (grep $_->has_changes, @autocommit) {
      my $message= join "\n",
         'Auto-commit packages fetched for branch '.$self->name,
         '',
         'For $archive_tree->import_modules:',
         map("  - $_ ".$reqs->requirements_for_module($_), @initial_list),
         '';
      $mirror->commit($message);
   }
   return \%imported_dists;
}


sub import_cpanfile_snapshot($self, $snapshot_spec, %options) {
   my %imported_dists;

   my $sources= $options{sources} // $self->default_import_sources;
   $sources && @$sources
      or croak "No import sources specified";
   # coerce every source name to an ArchiveTree object
   my @autocommit;
   for (@$sources) {
      unless (ref $_ and $_->can('package_details')) {
         my $t= $self->parent->get_archive_tree($_)
            or croak "No such archive tree $_";
         # If we've created new objects for MirrorTree and the MirrorTree has autofetch
         # enabled, then we also need to commit those changes before returning.
         push @autocommit, $t if $t->can('autofetch') && $t->autofetch;
         $_= $t;
      }
   }

   dist: for my $dist_name (sort keys %$snapshot_spec) {
      my $dist_info= $snapshot_spec->{$dist_name};
      # Locate 'pathname'
      my $author_path= $dist_info->{pathname};
      unless ($author_path) {
         my $msg= "Dist $dist_name lacks 'pathname' attribute";
         $options{partial}? $log->notice($msg) : croak $msg;
         next;
      }
      # Which source has this file?
      for my $source (@$sources) {
         $log->debugf("check %s for %s", $source->name, $author_path);
         next unless $source->get_path("authors/id/$author_path")
            || $source->dist_storage($author_path);
         $self->import_dist($source, $author_path);
         $imported_dists{$author_path}= $source;
         # Update index with the modules provided by this distribution if it wasn't imported
         # from $source by import_dist.
         if (!$source->package_details->{by_dist}{$author_path}) {
            # Fall back to the 'provides' from the cpanfile.snapshot
            if (ref $dist_info->{provides} eq 'HASH') {
               $self->index_distribution($author_path, $dist_info->{provides});
            } else {
               my $msg= "Snapshot lacks 'provides' for $dist_name, and not indexed in ".$source->name." either";
               $options{partial}? $log->notice($msg) : croak $msg;
            }
         }
         next dist;
      }
      my $msg= "No source contains file $author_path";
      $options{partial}? $log->notice($msg) : croak $msg;
   }
   # If any sources are 'autofetch' and caller didn't supply the MirrorTree object,
   # commit the changes before returning.
   for my $mirror (grep $_->has_changes, @autocommit) {
      my $message= join "\n",
         'Auto-commit packages fetched for branch '.$self->name,
         '',
         'For $archive_tree->import_cpanfile_snapshot',
         '';
      $mirror->commit($message);
   }
   return \%imported_dists;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::ArchiveTree - An object managing a CPAN file structure in a Git Tree

=head1 DESCRIPTION

This object represents a tree of files matching the layout of CPAN.  It may be an actual mirror
of an upstream CPAN/DarkPAN, or it may be a local curated collection of modules intended to
provide pinned versions for an application.  Mirrors (meaning *every* package from upstream is
listed in the index and fetched on demand) are represented by the subclass
L<MirrorTree|CPAN::InGit::MirrorTree> which implements the fetching of files from
upstream.  This class only contains methods to import distributions from other Git branches.

Distributions in C<authors/id/X/XX/XXXXX> should be kept identical to the public CPAN copy.
Local changes/patches to those files should be given a new distribution name under
C<authors/id/L/LO/LOCAL>.  The "provides" list (of modules) of a public CPAN distribution will be kept
the same as reported by public CPAN (for security, so that a dist without permission to index a
module still can't claim that name) but the "provides" list of a local distribution will always
take precedence in the indexing.

=head1 ATTRIBUTES

=head2 name

A human-readable name for this ArchiveTree instance.  Defaults to the branch name, when loaded
from a branch.  When loaded by L<CPAN::InGit/get_archive_tree> it is set to tag or sha1 if a
branch is not available.

=head2 config

A hashref of configuration stored in the tree, and lazily-loaded.

=head2 config_blob

Returns the Blob of the C<cpan_ingit.conf> file, or C<undef> if it doesn't exist.

=head2 canonical_url

The URL to be advertised in 02packages.details.txt, when written by this module.

=head2 default_import_sources

List of other branch names which the L</import_modules> should search.

=head2 corelist_perl_version

Version of perl which should be considered when deciding whether a module already exists in the
core distribution or whether it should be fetched from CPAN.

=head2 package_details

The parsed contents of C<modules/02package_details.txt>:

  {
    last_update => # Time::Piece of last-update
    by_module   => { $module_name => [ $mod, $ver, $path ] },
    by_dist     => { $author_path => [ [ $mod, $ver, $path ], ... ] },
  }

The C<by_module> and C<by_dist> hashres refer to the same row arrayrefs.

=head1 METHODS

=head2 load_config

  %attrs= $archive_tree->load_config();

Load the configuration of this ArchiveTree from the config file within the git tree.
(path C<< /cpan_ingit.json >>)

=head2 write_config

  $archive_tree->write_config($config);

Create a new /cpan_ingit.json from the L</config> attribute of this ArchiveTree.  By default
This stages the change (see L<CPAN::InGit::MutableTree>) but does not commit it.

=head2 package_details_blob

Returns the Blob of the C<modules/02packages.details.txt> file, or C<undef> if it doesn't exist.

=head2 parse_package_details

Parse C<< modules/02packages.details.txt.gz >> into a structure matching the description in
attribute L</package_details>.

=head2 write_package_details

Write C<< modules/02packages.details.txt >> from the current value of attribute L</package_details>.
This adds it to the pending changes to the tree, but does not commit it.

=head2 index_distribution

  $tree->index_distribution($author_path, \%package_versions);

Make this distribution the provider of the supplied packages and versions. Replace
its previous package list and write the updated index to the tree.

=head2 has_module

  $bool= $atree->has_module($mod_name);
  $bool= $atree->has_module($mod_name, $version_requirement);

=head2 get_module_version

  $ver= $atree->get_module_version($mod_name);

=head2 get_module_dist

  $ver= $atree->get_module_dist($mod_name);

=head2 find_upgrades

  my $list= $archive_tree->find_upgrades(sources => \@other_archive_trees);
  # [
  #   {
  #     author_path => 'A/AU/AUTHOR/Example-1.00.tar.gz',
  #     dist        => 'Example',
  #     version     => '1.00',
  #     upgrades    => [
  #       { author_path => 'A/AU/AUTHOR/Example-1.02.tar.gz', dist => 'Example', version => '1.02',
  #         source => 'www_cpan_org', kind => 'upgrade',
  #         modules => { 'Example' => [ '1.00', '1.02' ] } },
  #       { author_path => 'A/AU/AUTHOR/Example-Util-0.01.tar.gz', dist => 'Example-Util', version => '0.01',
  #         source => 'www_cpan_org', kind => 'moved',
  #         modules => { 'Example::Util' => [ '1.00', '1.01' ] } },
  #     ],
  #     left_behind   => [ 'Example::Old' ],
  #     not_in_source => [ 'Example::Private' ],
  #   },
  #   ...
  # ]

Compare the index of this tree with the index of other trees (by default, the trees named in
L</default_import_sources>) and return every distribution of this tree for which a newer
distribution is available, sorted by author path.

The comparison starts from the modules, because a module can move from one distribution to
another.  Each module of this tree is looked up in the sources, taking the source with the
highest version of it.  The modules are then grouped by the pair of (distribution here,
distribution there), and each pair becomes an element of C<upgrades> if it is newer:

=over

=item C<< kind => 'upgrade' >>

The other distribution has the same name and a higher release version.

=item C<< kind => 'moved' >>

The other distribution has a different name, and a higher version of at least one module.

=back

Each element of C<sources> is an ArchiveTree, or a hashref of
C<< { name => $name, by_module => \%by_module } >> in the format of L</package_details>, for
a caller that has its own snapshot of an index.  The option C<dists> (an arrayref of author
paths) limits the comparison to those distributions of this tree.

C<modules> has the version of each module here and there.  C<left_behind> lists the modules
which the sources still attribute to the distribution of this tree; typically, modules that
were removed from the newer release.  C<not_in_source> lists the modules that no source
provides.  Both are omitted when empty.

=head2 find_module_source

  my $found= $archive_tree->find_module_source($module_name, sources => \@sources);
  # { module => 'Example', version => '1.02', author_path => 'A/AU/AUTHOR/Example-1.02.tar.gz',
  #   source => 'www_cpan_org' }

Look up one module in the sources (as described for L</find_upgrades>, which uses this same
selection) and return the one with the highest version of it, or C<undef> if no source
provides it.  The first source wins a tie.

=head2 meta_path_for_dist

  $author_path= $archive_tree->meta_path_for_dist($author_path);

Return the author path for the .meta file corresponding with the distribution at an author path.
This is just a simple replacement of file extension that accounts for some special cases.

=head2 import_dist

  $archive_tree->import_dist($peer_tree, $author_path, %options);

Fetch an C<$author_path> from another tree, and update the module index to assign ownership of
the same modules as this dist had in the other tree.  The tree is written, but not committed.
This can change ownership of modules to this dist from another dist that claimed them.
Warn about packages the archive claims that the peer index does not register for
this distribution.

The C<.meta> file of the distribution is copied from the peer as well.  If the peer doesn't
have one, it is written from the C<META.json> or C<META.yml> found inside the distribution.

=head2 dist_storage

  my $storage= $tree->dist_storage($author_path);

Returns C<'archive'> if the distribution is stored in this tree as an archive file,
C<'unpacked'> if it is stored as a directory of files (plus C<.meta> file) from which a
C<.tar.gz> can be generated, or C<undef> if this tree does not contain the distribution.
This never fetches anything from the upstream of a mirror.

=head2 get_dist

  my $dist= $tree->get_dist($author_path, %options);

Return a L<CPAN::InGit::DistTree> for browsing, inspecting, or comparing the files of a
distribution, or C<undef> if this tree does not contain the distribution.  An archive file is
unpacked the first time it is requested and cached in L<CPAN::InGit/dist_cache_repo>.
This dies if the archive can't be unpacked.

Options:

=over

=item fetch

For a L<MirrorTree|CPAN::InGit::MirrorTree> which lacks the distribution, download it
from upstream and unpack it into the cache, without adding the archive to the mirror.

=back

=head2 get_distfile

  my $bytes_ref= $tree->get_distfile($author_path);

Return a scalar reference to the archive, or C<undef> if unavailable.
For an unpacked distribution, generate the archive from its Git tree.
Mirrors can fetch the archive without adding it to the tree.

=head2 localize_module

  my $author_path= $tree->localize_module($package, %options);

Look up a package in this tree, then in the configured import sources (or the
C<sources> option). Unpack its distribution under the LOCAL author and preserve
the package names and versions registered by the source.

=head2 add_local_dist

  my $author_path= $tree->add_local_dist($filename, \$bytes, %options);

Unpack a distribution under C<authors/id/L/LO/LOCAL>, write its metadata and
register its packages in the index. Return the C<.tar.gz> author path that
serves the unpacked distribution. Supply C<versions> as a hash of indexed
packages and versions when importing from a known manifest.

=head2 get_dist_meta

  $meta= $archive_tree->get_dist_meta($author_path);

Return the L<CPAN::Meta> for the distribution, or C<undef> if unknown.  This comes from
the C<.meta> file stored next to the distribution, and otherwise from inspecting the
contents of the distribution (see L<CPAN::InGit::DistTree/meta>).

=head2 import_modules

  # {
  #   'Example::Module' => '>=0.011',
  #   'Some::Module'    => '',   # any version
  # }
  my $imported= $archive_tree->import_modules(\%module_version_spec);
  # {
  #   'A/AU/AUTHOR/Example-Module-1.2.3.tar.gz' => $from_source,
  #   ...
  # }

This method processes a list of module requirements to pull in matching modules and only as many
dependencies as are required.  It starts by checking whether this branch contains a module that
meets the requirements.  If not, it checks the mirror branches listed in "import_sources".
If this or any "import_source" branch has an "upstream_url", it may pull from remote into that
branch.

The intended workflow is that you have one branch tracking www.cpan.org and pulling in packages
automatically as needed, and then perhaps a branch where you review the modules before importing
them, and maybe a branch where you upload private DarkPAN modules, and then any number of
application branches that import from the reviewed branch or the DarkPAN branch. This way you
separate the process of building an application's module collection from the process of
reviewing public modules.

All changes will be pulled into this MutableTree object, but not committed.  If this is the
working branch, the index also gets updated.

=head2 import_cpanfile_snapshot

  $archive_tree->import_cpanfile_snapshot(\%distribution_spec);

This function takes a data structure from a cpanfile.snapshot (parsed via
L<CPAN::InGit/parse_cpanfile_snapshot> ) and fetches the exact distribution files listed, and
writes all the "provides" information into the L</package_details>.

This does not check any of the 'requires', on the assumption that the snapshot represents a
complete package collection.

=head1 VERSION

version 0.007

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
