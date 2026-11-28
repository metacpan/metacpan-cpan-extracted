package CPAN::InGit::DistTree;
our $VERSION = '0.007'; # VERSION
# ABSTRACT: A MutableTree holding the files of one CPAN distribution


use Carp;
use Scalar::Util 'blessed';
use Archive::Tar;
use CPAN::Meta 2.150010;
use File::Temp;
use IO::Uncompress::Unzip qw( $UnzipError );
use Log::Any '$log';
use Moo;
use version ();
use v5.36;

extends 'CPAN::InGit::MutableTree';

my $dist_ext= qr/(?:zip|tar(?:\.gz|\.bz2|\.xz)?|tgz|tbz2|txz)/;


has name        => ( is => 'ro', required => 1 );
has author_path => ( is => 'ro' );
has storage     => ( is => 'ro' );

sub git_repo { shift->parent->dist_cache_repo }

sub BUILD($self, $args, @) {
   # The tree might have been loaded from the main repo.  Make all further access go through
   # the cache repo, so that every object being compared comes from the same Repository.
   $self->tree(Git::Raw::Tree->lookup($self->git_repo, $self->tree->id))
      if $self->tree;
}


sub parse_filename($class, $path) {
   return $path =~ m{(?:^|[/\\])([A-Za-z0-9_][A-Za-z0-9_.+-]*)\.($dist_ext)\z}? ($1, $2) : ();
}


sub parse_release($class, $path) {
   my ($name)= $class->parse_filename($path) or return;
   return $name =~ /\A(.+)-(v?\d[\d._]*)(?:-TRIAL)?\z/? ($1, $2) : ();
}


sub new_from_archive($class, %attrs) {
   my $filename= delete $attrs{filename} // croak "Missing 'filename'";
   my $bytes= delete $attrs{data} // croak "Missing 'data'";
   my ($name)= $class->parse_filename($filename)
      or croak "Unsupported distribution filename '$filename'";
   my $files= _read_archive($filename, $bytes);
   my $self= $class->new(name => $name, %attrs);
   $self->set_path($_, $files->{$_}[0], mode => $files->{$_}[1])
      for keys %$files;
   $self->update_tree;
   $self->has_changes(0);
   return $self;
}

sub _read_archive($filename, $bytes) {
   my $files= $filename =~ /\.zip\z/? _read_zip($filename, $bytes) : _read_tar($filename, $bytes);
   croak "No files in $filename" unless keys %$files;

   # CPAN releases usually wrap the distribution in a single top-level directory.
   my $prefix= _dist_wrapper(keys %$files);
   $files= { map +( substr($_, 1 + length($prefix)) => $files->{$_} ), keys %$files }
      if defined $prefix;

   for my $path (keys %$files) {
      my $parent= $path;
      while ($parent =~ s{/[^/]+\z}{}) {
         croak "Conflicting archive paths '$parent' and '$path' in $filename"
            if exists $files->{$parent};
      }
   }
   return $files;
}

# Return the name of the top-level directory if it contains every file of the archive and
# isn't one of the directory names that are normal for the root of a distribution.
sub _dist_wrapper(@paths) {
   my ($prefix)= ($paths[0] // '') =~ m{^([^/]+)/};
   return undef unless defined $prefix && $prefix !~ /\A(?:lib|t|xt|inc|script|bin|share)\z/;
   return undef if grep index($_, "$prefix/") != 0, @paths;
   return $prefix;
}

sub _check_archive_path($path, $filename) {
   croak "Unsafe archive path '$path' in $filename"
      if $path =~ m{[\\:\x00-\x1f\x7f]}
      || grep { $_ eq '' || /\A(?:\.|\.\.|\.git[ .]*|git~1[ .]*)\z/i } split m{/}, $path, -1;
}

sub _add_archive_entry($files, $path, $content, $mode, $filename) {
   $path =~ s{\A(?:\./)+}{};
   _check_archive_path($path, $filename);
   croak "Duplicate archive path '$path' in $filename" if exists $files->{$path};
   $files->{$path}= [ $content, $mode ];
}

sub _read_tar($filename, $bytes) {
   # Archive::Tar's auto-detection of the compression only works when reading from a file
   my $tmp= File::Temp->new;
   binmode $tmp, ':raw' or croak "binmode($tmp): $!";
   $tmp->print($$bytes) && $tmp->flush or croak "write($tmp): $!";
   my $tar= Archive::Tar->new;
   $tar->read("$tmp") && !$tar->error or croak "Cannot read $filename: ".$tar->error;
   my %files;
   for my $entry ($tar->get_files) {
      my $name= $entry->full_path;
      if ($entry->is_dir) {
         # Git doesn't store directories, only the files in them
      } elsif ($entry->is_file) {
         _add_archive_entry(\%files, $name, $entry->get_content_by_ref,
            $entry->mode & 0111? 0100755 : 0100644, $filename);
      } elsif ($entry->is_symlink) {
         my $target= $entry->linkname;
         _add_archive_entry(\%files, $name, \$target, 0120000, $filename);
      } else {
         croak "Unsupported TAR entry '$name' in $filename";
      }
   }
   return \%files;
}

sub _read_zip($filename, $bytes) {
   my $zip= IO::Uncompress::Unzip->new($bytes, Transparent => 0, Strict => 1)
      or croak "Cannot read $filename: $UnzipError";
   my %files;
   my $stream;
   for ($stream= 1; $stream > 0; $stream= $zip->nextStream) {
      my $name= $zip->getHeaderInfo->{Name};
      my ($chunk, $content, $read)= ('', '');
      $content .= $chunk while ($read= $zip->read($chunk)) > 0;
      croak "Cannot read $filename: $UnzipError" if $read < 0;
      next if $name =~ m{/\z}; # directory
      _add_archive_entry(\%files, $name, \$content, 0100644, $filename);
   }
   croak "Cannot read $filename: $UnzipError" if $stream < 0;
   return \%files;
}


sub _walk($self, $callback, $tree=undef, $prefix='') {
   $tree //= $self->_effective_tree // return;
   for my $ent ($tree->entries) {
      if ($ent->file_mode == 0040000) {
         $self->_walk($callback, $ent->object, $prefix.$ent->name.'/');
      } else {
         $callback->($prefix.$ent->name, $ent);
      }
   }
}

sub files($self) {
   my %files;
   $self->_walk(sub ($path, $ent) { $files{$path}= [ \($ent->object->content), $ent->file_mode ] });
   return \%files;
}

sub file_list($self) {
   my @paths;
   $self->_walk(sub ($path, $ent) { push @paths, $path });
   return sort @paths;
}


sub check_symlinks($self) {
   my %mode;
   $self->_walk(sub ($path, $ent) { $mode{$path}= $ent->file_mode });
   my $label= $self->author_path // $self->name;
   for my $path (grep $mode{$_} == 0120000, sort keys %mode) {
      my $target= $self->get_path($path)->[0]->content;
      my @parent= split '/', $path;
      pop @parent;
      croak "Unsafe symlink '$path' in $label" if $target =~ m{^(?:/|\z)|[\\:\x00]};
      for (split '/', $target) {
         next if $_ eq '.' || $_ eq '';
         croak "Unsafe symlink '$path' in $label"
            if ($mode{join '/', @parent} // 0) == 0120000;
         if ($_ eq '..') {
            croak "Unsafe symlink '$path' in $label" unless @parent;
            pop @parent;
         } else {
            _check_archive_path($_, $label);
            push @parent, $_;
         }
      }
   }
   return $self;
}


has _meta_info => ( is => 'lazy' );
sub meta($self)        { $self->_meta_info->[0] }
sub meta_source($self) { $self->_meta_info->[1] }

sub _build__meta_info($self) {
   my $label= $self->author_path // $self->name;
   for my $file (qw( META.json META.yml )) {
      my $ent= $self->get_path($file);
      next unless $ent && $ent->[0]->is_blob && $ent->[1] != 0120000;
      my $data= $ent->[0]->content;
      my $meta= eval { $file eq 'META.json'? CPAN::Meta->load_json_string($data)
                                           : CPAN::Meta->load_yaml_string($data) };
      return [ $meta, $file ] if $meta;
      $log->warn("Failed to load $file from $label: $@");
   }
   my $name= $self->name;
   my ($dist, $ver)= $name =~ /\A(.+)-([v0-9][0-9._]*)\z/;
   my $meta= CPAN::Meta->new({
      'meta-spec' => { version => 2 },
      name => $dist // $name,
      version => defined $ver && version::is_lax($ver)? $ver : '0',
      abstract => $dist // $name,
      author => ['unknown'],
      dynamic_config => 1,
      generated_by => 'CPAN::InGit',
      license => ['unknown'],
      release_status => 'stable',
   });
   return [ $meta, 'synthesized' ];
}


has provides => ( is => 'lazy' );
sub _build_provides($self) {
   my $declared= $self->meta->as_struct({ version => 2 })->{provides};
   return $declared // $self->_scan_provides;
}

sub _scan_provides($self) {
   my $meta= $self->meta;
   my %provides;
   my $package_name= qr/[A-Za-z_]\w*(?:(?:::|')[A-Za-z_]\w*)*/;
   my $literal_version= qr/v?[0-9][0-9._]*/;
   my @pm_files;
   $self->_walk(sub ($path, $ent) {
      push @pm_files, [ $path, $ent ]
         if $path =~ /\.pm\z/ && $path !~ m{^(?:t|xt|inc|script|bin|blib|fatlib|local)/}
            && $ent->file_mode != 0120000 && $meta->should_index_file($path);
   });
   for (sort { $a->[0] cmp $b->[0] } @pm_files) {
      my ($path, $ent)= @$_;
      my $source= $ent->object->content;
      $source =~ s/^=(?!cut\b)\w.*?^=cut[^\n]*//msg;
      $source =~ s/^__(?:END|DATA)__\b.*//ms;
      my $pkg;
      # Inspect declarations and literal VERSION values without loading the module.
      while ($source =~ /
         (?: ^ | (?<=[;{]) ) \h*
         (?:
            package\s+($package_name)(?:\s+($literal_version))?\s*(?=[;{])
            |
            (?:(?:our|local)\s+)?\$(?:($package_name)(?:::|'))?VERSION\s*=\s*
            (?:(version->(?:new|parse|declare))\s*\(\s*)?
            (['"]?)($literal_version)\5\s*(?(4)\)\s*) (?=;)
         )
      /xmg) {
         my ($declared, $pkg_version, $qualified, $literal)= ($1, $2, $3, $6);
         $pkg= $declared if defined $declared;
         my $name= $qualified // $pkg // next;
         $name =~ s/'/::/g;
         next if $name eq 'main' || !$meta->should_index_package($name);
         my $info= ($provides{$name} //= { file => $path });
         my $ver= $pkg_version // $literal;
         $info->{version} //= $ver if defined $ver && version::is_lax($ver);
      }
   }
   return \%provides;
}


sub changes_file($self) {
   my $root= $self->list_dir // return;
   my @files= sort grep { ($root->{$_}[1] & 0170000) == 0100000 } keys %$root;
   for my $name (qw( Changes ChangeLog NEWS )) {
      my ($match)= grep /\A\Q$name\E(?:\.(?:txt|md|markdown|rst|pod))?\z/i, @files;
      return ($match, $root->{$match}[0]) if defined $match;
   }
   return;
}


sub diff_prereqs($self, @args) {
   my ($from, $to)= map {
      blessed($_) && $_->isa('CPAN::Meta')? $_
      : blessed($_) && $_->can('meta')? $_->meta
      : croak "Expected DistTree or CPAN::Meta";
   } (ref $self? ($self, $args[0]) : @args[0,1]);
   ($from, $to)= map $_->effective_prereqs->as_string_hash, $from, $to;
   my %diff;
   for my $phase (keys %{{ %$from, %$to }}) {
      for my $type (keys %{{ %{ $from->{$phase} // {} }, %{ $to->{$phase} // {} } }}) {
         my $old= $from->{$phase}{$type} // {};
         my $new= $to->{$phase}{$type} // {};
         for my $mod (keys %{{ %$old, %$new }}) {
            $diff{$phase}{$type}{$mod}= [ $old->{$mod}, $new->{$mod} ]
               unless exists $old->{$mod} && exists $new->{$mod} && $old->{$mod} eq $new->{$mod};
         }
      }
   }
   return \%diff;
}


sub summary($self) {
   my $tree= $self->_effective_tree;
   return {
      name        => $self->name,
      author_path => $self->author_path,
      version     => $self->meta->version,
      storage     => $self->storage,
      meta_source => $self->meta_source,
      tree        => $tree && $tree->id,
   };
}


our $generated_file_pattern= qr{\A(?:META\.json|META\.yml|MYMETA\.[^/]+|MANIFEST|SIGNATURE|ppport\.h|inc/.*)\z};

sub compare($self, $other, %opts) {
   blessed($other) && $other->can('changes_file') or croak "Expected a DistTree";
   my $want_patch= $opts{patch} // 1;
   my $max_size= $opts{max_patch_size} // 200_000;
   my $paths= $opts{paths} && @{ $opts{paths} }? $opts{paths} : undef;
   my $skip_generated= !$paths && !$opts{include_generated};
   my @versions= ($opts{hide_version_diff} // 1)? ( $self->meta->version, $other->meta->version ) : ();

   my ($changes_from)= $self->changes_file;
   my ($changes_to)= $other->changes_file;
   my $files= $self->diff($other, patch => 1, context_lines => $opts{context_lines}, paths => $paths);
   my $changes;
   my %stats= ( files => scalar @$files, additions => 0, deletions => 0 );
   for my $file (@$files) {
      $stats{additions} += $file->{additions};
      $stats{deletions} += $file->{deletions};
      my $patch= delete $file->{patch};
      # Git deals in bytes.  Assume UTF-8 where it is valid, so the report is made of characters.
      utf8::decode($patch);
      if (defined $changes_to && $file->{path} eq $changes_to && !$file->{binary}) {
         $changes= {
            path  => $changes_to,
            added => join('', map /\A\+(?!\+\+ )(.*\n?)\z/s? $1 : (), split /^/m, $patch),
            patch => $patch,
         };
         $changes->{old_path}= $file->{old_path} if defined $file->{old_path};
         $file->{skipped}= 'changes';
      }
      elsif ($file->{binary}) {
         $file->{skipped}= 'binary';
      }
      elsif ($skip_generated && $file->{path} =~ $generated_file_pattern) {
         $file->{skipped}= 'generated';
      }
      elsif (@versions and my $hidden= _hide_version_hunks(\$patch, @versions)
         and $patch !~ /^\@\@ /m
      ) {
         $file->{skipped}= 'version';
      }
      elsif ($max_size && length $patch > $max_size) {
         $file->{skipped}= 'too large';
      }
      elsif ($want_patch) {
         $file->{patch}= $patch;
         $file->{hidden_version_hunks}= $hidden if $hidden;
      }
      utf8::decode($file->{$_}) for grep defined $file->{$_}, qw( path old_path );
   }
   if ($changes) {
      utf8::decode($changes->{$_}) for grep defined $changes->{$_}, qw( path old_path );
   }
   return {
      from    => $self->summary,
      to      => $other->summary,
      prereqs => $self->diff_prereqs($other),
      changes => $changes,
      files   => $files,
      stats   => \%stats,
   };
}

# Remove from a unified diff each hunk which only changes $v_from to $v_to on one line that
# mentions "version".  Returns the number of hunks removed.
sub _hide_version_hunks($patch_ref, $v_from, $v_to) {
   return 0 unless defined $v_from && defined $v_to;
   s/\Av//i for $v_from, $v_to;
   return 0 unless length $v_from && length $v_to && $v_from ne $v_to;
   # A version must not be part of a longer number, like 1.02 within 11.02 or 1.02.3
   my ($re_from, $re_to)= map qr/(?<![\d.])v?\Q$_\E(?![\d_]|\.\d)/i, $v_from, $v_to;
   my ($head, @hunks)= split /^(?=\@\@ )/m, $$patch_ref;
   my $hidden= 0;
   @hunks= grep {
      my @del= /^-(.*)$/mg;
      my @add= /^\+(.*)$/mg;
      my $is_version_bump= 0;
      if (@del == 1 && @add == 1 && "$del[0]$add[0]" =~ /version/i) {
         my ($old, $new)= ($del[0], $add[0]);
         $is_version_bump= ($old =~ s/$re_from/\0/g) && ($new =~ s/$re_to/\0/g) && $old eq $new;
      }
      $hidden++ if $is_version_bump;
      !$is_version_bump;
   } @hunks;
   $$patch_ref= join '', $head, @hunks if $hidden;
   return $hidden;
}


sub format_comparison($class, $report, %opts) {
   my ($from, $to)= @{$report}{qw( from to )};
   my $out= '';
   for ([ 'From', $from ], [ 'To', $to ]) {
      my ($label, $d)= @$_;
      $out .= sprintf "%-5s %s", "$label:", $d->{author_path} // $d->{name};
      $out .= " (version $d->{version})" if defined $d->{version};
      $out .= " [no META file; prereqs unknown]" if $d->{meta_source} eq 'synthesized';
      $out .= "\n";
   }

   $out .= "\n== Prereq changes ==\n";
   my $prereqs= $report->{prereqs};
   if (!%$prereqs) {
      $out .= "(none)\n";
   } else {
      my %phase_order= ( configure => 1, build => 2, runtime => 3, test => 4, develop => 5 );
      for my $phase (sort { ($phase_order{$a} // 9) <=> ($phase_order{$b} // 9) or $a cmp $b } keys %$prereqs) {
         for my $type (sort keys %{ $prereqs->{$phase} }) {
            my $mods= $prereqs->{$phase}{$type};
            for my $mod (sort keys %$mods) {
               my ($old, $new)= @{ $mods->{$mod} };
               $out .= !defined $old? "+ $phase $type $mod $new\n"
                     : !defined $new? "- $phase $type $mod $old\n"
                     : "~ $phase $type $mod $old -> $new\n";
            }
         }
      }
   }

   $out .= "\n== Change log ==\n";
   if (my $changes= $report->{changes}) {
      $out .= "($changes->{path}, added lines)\n$changes->{added}";
      $out .= "\n" unless $out =~ /\n\z/;
   } else {
      $out .= "(no change log changes)\n";
   }

   my ($files, $stats)= @{$report}{qw( files stats )};
   $out .= sprintf "\n== Files changed: %d (+%d -%d) ==\n", @{$stats}{qw( files additions deletions )};
   my %letter= ( added => 'A', deleted => 'D', modified => 'M', renamed => 'R', copied => 'C', type_change => 'T' );
   for my $f (@$files) {
      $out .= sprintf "%s %s%s  +%d -%d%s\n", $letter{$f->{status}} // '?',
         (defined $f->{old_path}? "$f->{old_path} -> " : ''), $f->{path},
         $f->{additions}, $f->{deletions},
         ($f->{skipped} && $f->{skipped} ne 'changes'? "  [patch omitted: $f->{skipped}]"
          : $f->{hidden_version_hunks}? "  [version-only hunks hidden: $f->{hidden_version_hunks}]" : '');
   }

   if ($opts{patch} // 1) {
      my @patches= grep defined, map $_->{patch}, @$files;
      if (@patches) {
         $out .= "\n== Patches ==\n";
         for (@patches) {
            $out .= $_;
            $out .= "\n" unless $out =~ /\n\z/;
         }
      }
   }
   return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::DistTree - A MutableTree holding the files of one CPAN distribution

=head1 SYNOPSIS

  my $old= $app_tree->get_dist('A/AU/AUTHOR/Example-1.00.tar.gz');
  my $new= $cpan_tree->get_dist('A/AU/AUTHOR/Example-1.02.tar.gz', fetch => 1);

  # Browse it
  my $entries= $new->list_dir('lib');
  my ($blob, $mode)= @{ $new->get_path('lib/Example.pm') };
  my ($changes_name, $changes_blob)= $new->changes_file;

  # Inspect it
  my $prereqs= $new->meta->effective_prereqs;

  # Compare it
  my $report= $old->compare($new);

=head1 DESCRIPTION

This is a L<MutableTree|CPAN::InGit::MutableTree> holding the contents of a single
distribution.  The files are always found at the root of the tree; the customary
C<Dist-Name-1.23/> wrapper directory of a distribution archive is removed, so that the same
file has the same path in every version of the distribution.

You normally get one from L<CPAN::InGit::ArchiveTree/get_dist>, which handles distributions
stored as archive files (unpacked once, then cached in L<CPAN::InGit/dist_cache_repo>) as well
as distributions stored unpacked in the Git branch.  A DistTree is not connected to any
branch, and so while it has the methods to make changes, it can't commit them.

=head1 ATTRIBUTES

=head2 name

The release name of the distribution, like C<Example-1.02>.  (the archive file name without
its extension)

=head2 author_path

The path of this distribution relative to C<authors/id/>, if it came from an ArchiveTree.

=head2 storage

How the distribution was found: C<'archive'> for an archive file in the ArchiveTree,
C<'unpacked'> for a directory of files in the ArchiveTree, or C<'upstream'> for an archive
downloaded from the upstream of a mirror without being added to the mirror.

=head2 git_repo

For a DistTree this is the L<CPAN::InGit/dist_cache_repo>, which can read the objects of
the main repository as well as the cache of unpacked archives.

=head1 METHODS

=head2 parse_filename

  my ($name, $extension)= CPAN::InGit::DistTree->parse_filename($path);

Split the file name of a distribution archive into its release L</name> and one of the
supported archive extensions.  Returns an empty list if the name doesn't look like a
distribution archive.

=head2 parse_release

  my ($dist_name, $version)= CPAN::InGit::DistTree->parse_release($path);
  # 'A/AU/AUTHOR/Example-Dist-1.02.tar.gz' => ('Example-Dist', '1.02')

Split the file name of a distribution archive into the name of the distribution and the
version of the release.  Returns an empty list if the name doesn't have that form.

=head2 new_from_archive

  my $dist= CPAN::InGit::DistTree->new_from_archive(
    parent   => $cpan_repo,
    filename => 'Example-1.02.tar.gz',
    data     => \$bytes,
    %other_attributes
  );

Unpack a tar or zip archive into Git objects of the L<CPAN::InGit/dist_cache_repo>.  This
dies if the archive can't be read, or contains anything other than files, directories, and
symlinks, or has paths that are unsafe to store in Git (like C<..> or C<.git>).

This does not consult or update the cache; see L<CPAN::InGit::ArchiveTree/get_dist>.

=head2 files

  my $files= $dist->files;
  # { 'lib/Example.pm' => [ \$bytes, $mode ], ... }

Return every file of the distribution, in the form accepted by
L<CPAN::InGit::MutableTree/set_path> for a directory.

=head2 file_list

  my @paths= $dist->file_list;

Return the sorted paths of every file (and symlink) in the distribution.

=head2 check_symlinks

  $dist->check_symlinks;

Die if any symlink of the distribution is absolute, or refers to a path outside of the
distribution, or passes through another symlink.  Such links are harmless while stored in Git,
but should be checked before writing the files to a directory.

=head2 meta

  my $cpan_meta= $dist->meta;

Return a L<CPAN::Meta> object for the distribution, loaded from its C<META.json> or
C<META.yml>.  If the distribution has neither (or they can't be parsed), this returns a
minimal object built from the L</name>, which has no prereqs.  Check L</meta_source> to
tell the difference.

=head2 meta_source

Returns C<'META.json'>, C<'META.yml'>, or C<'synthesized'>, describing where L</meta> came from.

=head2 provides

  my $provides= $dist->provides;
  # { 'Example' => { file => 'lib/Example.pm', version => '1.02' }, ... }

Return the packages of this distribution, in the format of the C<provides> of the CPAN Meta
Spec.  If the L</meta> doesn't declare them, they are found by scanning the C<.pm> files for
package declarations and literal C<$VERSION> assignments.  No code from the distribution is
ever executed.

=head2 changes_file

  my ($name, $blob)= $dist->changes_file;

Find the change log of the distribution, looking for the conventional names C<Changes>,
C<ChangeLog>, and C<NEWS> (in that order of preference, in any letter case, optionally with an
extension like C<.md>) in the root of the distribution.  Returns an empty list if there isn't
one.

=head2 diff_prereqs

  my $changes= $dist->diff_prereqs($other_dist);
  # {
  #   runtime => {
  #     requires => {
  #       'Added::Module'   => [ undef,  '1.5' ],
  #       'Changed::Module' => [ '0.10', '0.24' ],
  #       'Removed::Module' => [ '0',    undef ],
  #     },
  #   },
  # }

Compare the prereqs declared by the L</meta> of this distribution with those of another
DistTree (or a L<CPAN::Meta> object), returning only the phases, relationships, and modules
which differ.  Each module has an arrayref of the version requirement in this distribution
and in the other, where C<undef> means it is not required at all.

This can also be called as a class method on two L<CPAN::Meta> objects:

  my $changes= CPAN::InGit::DistTree->diff_prereqs($meta_a, $meta_b);

=head2 summary

  my $info= $dist->summary;
  # { name => 'Example-1.02', author_path => 'A/AU/AUTHOR/Example-1.02.tar.gz',
  #   version => '1.02', storage => 'archive', meta_source => 'META.json', tree => $tree_id }

Return a hashref of plain scalars describing this distribution.

=head2 compare

  my $report= $dist->compare($other_dist, %options);
  # {
  #   from    => { name => 'Example-1.00', ... },   # see ->summary
  #   to      => { name => 'Example-1.02', ... },
  #   prereqs => { ... },                           # see ->diff_prereqs
  #   changes => {
  #     path  => 'Changes',
  #     added => "1.02 - 2026-01-02\n  - Fixed a bug\n",
  #     patch => "diff --git ...",
  #   },
  #   files   => [
  #     { path => 'lib/Example.pm', status => 'modified', additions => 3, deletions => 1,
  #       patch => "diff --git ...", ... },
  #     { path => 'META.json', status => 'modified', additions => 9, deletions => 9,
  #       skipped => 'generated', ... },
  #   ],
  #   stats   => { files => 2, additions => 12, deletions => 10 },
  # }

Build a complete report of what changed between this distribution and another, as a
structure of plain data which can be serialized or rendered as text or HTML.  It is intended
for reviewing an upgrade from this distribution to C<$other_dist>.

All text of the report (paths, patches, and change log) is decoded as UTF-8 where it is
valid UTF-8, so remember to encode it on output.

C<changes> is C<undef> unless C<$other_dist> has a L<change log|/changes_file> that differs
from the one in this distribution.  Its C<added> is the text of the lines that were added to
the change log.

C<files> has one element per changed file, as described in L<CPAN::InGit::MutableTree/diff>.
A file without a C<patch> has a C<skipped> attribute giving the reason: C<'generated'> for
files that are boilerplate or derived from other files (C<META.json>, C<META.yml>,
C<MANIFEST>, C<SIGNATURE>, C<ppport.h> and everything under C<inc/>), C<'binary'>,
C<'too large'>, C<'version'> when the only change was the version number (see
C<hide_version_diff>), or C<'changes'> for the change log which is reported separately.
A file whose patch had some of its hunks removed by C<hide_version_diff> has the number of
them in C<hidden_version_hunks>.  The C<additions> and C<deletions> always count every line.

Options:

=over

=item paths

Arrayref of paths (or git pathspecs) to limit the file comparison.  Naming paths also
disables skipping of generated files.

=item patch

Boolean, whether to include patches at all (default true).

=item context_lines

Number of unchanged lines around each change in the patches (default 3)

=item max_patch_size

Patches longer than this number of bytes are skipped as C<'too large'>.  (default 200_000,
and 0 means unlimited)

=item include_generated

Boolean, whether to include patches for generated files

=item hide_version_diff

Boolean (default true), whether to remove from the patches every hunk that does nothing but
change the version number.  Such a hunk removes one line and adds one line, the line
mentions C<version> (in any case), and the two lines are identical aside from the version of
this distribution having been replaced with the version of C<$other_dist>.  This hides the
C<$VERSION> declaration and the "version 1.02" POD line that change in every module of
every release.  The change log is not affected, and neither are generated files unless
their patches were requested with C<include_generated> or C<paths>.

=back

=head2 format_comparison

  my $text= CPAN::InGit::DistTree->format_comparison($report, %options);

Render the result of L</compare> as plain text: a header, the changed prereqs, the lines
added to the change log, a summary of the files changed, and then the patches.  The patches
are standard unified diffs.  Options:

=over

=item patch

Set to false to omit the patches

=back

=head1 VERSION

version 0.007

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
