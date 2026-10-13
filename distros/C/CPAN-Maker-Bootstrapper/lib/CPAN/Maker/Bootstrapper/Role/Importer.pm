package CPAN::Maker::Bootstrapper::Role::Importer;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use Carp;
use Cwd qw(abs_path);
use English qw(-no_match_vars);
use List::Util qw(none);
use Scalar::Util qw(reftype);

# not used yet
use CLI::Simple::Utils qw(slurp choose);
use Data::Dumper;
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp;

use Role::Tiny;

our $VERSION = '2.5.0';

########################################################################
sub cmd_import {
########################################################################
  my ($self) = @_;

  my ($import_manifest) = $self->get_args;

  die "usage: import manifest-file\n"
    if !$import_manifest;

  die sprintf "ERROR: %s does not exist or is not readable\n", $import_manifest
    if !-r $import_manifest;

  my $manifest = $self->_load_import_manifest($import_manifest);

  foreach my $key (qw(base-dir module import)) {
    next if exists $manifest->{$key};

    die "ERROR: import manifests must contain $key\n";
  }

  my $base_dir = abs_path( $manifest->{'base-dir'} );

  die sprintf "ERROR: %s does not specify a valid import path\n", $manifest->{'base-dir'}
    if !-d $base_dir;

  $manifest->{'base-dir'} = $base_dir;

  my $import_list = $manifest->{import};

  $self->_test_type( import => $import_list, 'ARRAY' );

  die "ERROR: import list must include at least a lib source\n"
    if none { ref $_ eq 'HASH' && exists $_->{lib} } @{$import_list};

  my $listing = $self->_manifest_file_listing($manifest);

  $self->set_import_file_listing($listing);

  if ( $self->get_dry_run ) {
    $self->_report_import_plan;
    return $SUCCESS;
  }

  local $ENV{SYNTAX_CHECKING} = 'off';

  return $self->_import_project(
    module       => $manifest->{module},
    import_paths => [$base_dir]
  );
}

########################################################################
sub _manifest_file_listing {
########################################################################
  my ( $self, $manifest ) = @_;

  my $base_dir = $manifest->{'base-dir'};
  my @files;

  foreach my $entry ( @{ $manifest->{import} } ) {
    $self->_test_type( import => $entry, 'HASH' );

    die "ERROR: each import entry must contain exactly one destination\n"
      if keys %{$entry} != 1;

    foreach my $destination ( sort keys %{$entry} ) {
      my $spec = $entry->{$destination};

      $self->_test_type( $destination => $spec, 'HASH' );

      $self->_importer_validate_import_destination( $destination, 'destination' );

      die sprintf "ERROR: import destination '%s' requires a path\n", $destination
        if !defined $spec->{path};

      if ( defined $spec->{dest} ) {
        $self->_importer_validate_import_destination( $spec->{dest}, 'dest' );

        $destination = File::Spec->catdir( $destination, $spec->{dest} );
      }

      my $extensions = $spec->{ext};

      if ( defined $extensions ) {
        my @extensions
          = ( reftype($extensions) // q{} ) eq 'ARRAY'
          ? @{$extensions}
          : ($extensions);

        foreach my $extension (@extensions) {
          next if $extension eq q{*};

          $self->_validate_import_regexp( $extension, 'ext' );
        }
      }

      my $paths = $spec->{path};

      if ( ( reftype($paths) // q{} ) ne 'ARRAY' ) {
        $paths = [$paths];
      }

      foreach my $path ( @{$paths} ) {
        my $source = File::Spec->file_name_is_absolute($path) ? $path : File::Spec->catfile( $base_dir, $path );

        $source = abs_path($source);

        croak sprintf 'ERROR: import source does not exist: %s', $path
          if !defined $source;

        my $relative_source = File::Spec->abs2rel( $source, $base_dir );
        $relative_source =~ s{\\}{/}gxsm;

        croak sprintf 'ERROR: import source is outside base-dir: %s', $path
          if $relative_source eq q{..}
          || $relative_source =~ m{\A[.][.]/}xsm;

        if ( -f $source ) {
          $self->_add_import_file(
            files       => \@files,
            source      => $source,
            destination => $destination,
            base_dir    => $base_dir
          );

          next;
        }
        elsif ( -d $source ) {
          my $recurse = $spec->{recurse} // $FALSE;

          my @exclusions;

          foreach my $exclude_set ( $manifest->{exclude}, $spec->{exclude} ) {
            next if !defined $exclude_set;

            if ( ( reftype($exclude_set) // q{} ) eq 'ARRAY' ) {
              push @exclusions, @{$exclude_set};
            }
            else {
              push @exclusions, $exclude_set;
            }
          }

          foreach my $exclude (@exclusions) {
            next if index( $exclude, q{/} ) >= 0;

            $self->_validate_import_regexp( $exclude, 'exclude' );
          }

          File::Find::find(
            { no_chdir => $TRUE,
              wanted   => sub {
                my $file = $File::Find::name;

                if ( -d $file ) {
                  if (
                    $file ne $source
                    && (!$recurse
                      || $self->_excluded_import_path( $file, $base_dir, \@exclusions ) )
                  ) {
                    $File::Find::prune = $TRUE;
                  }

                  return;
                }

                return if !-f $file;

                return
                  if $self->_excluded_import_path( $file, $base_dir, \@exclusions );

                return
                  if !$self->_matches_import_extension( $file, $spec->{ext} );

                my $relative = File::Spec->abs2rel( $file, $source );

                $self->_add_import_file(
                  files       => \@files,
                  source      => $file,
                  destination => $destination,
                  base_dir    => $base_dir,
                  filename    => $relative
                );

                return;
              },
            },
            $source
          );
        }
        else {
          croak sprintf 'ERROR: unsupported import source: %s', $path;
        }
      }
    }
  }

  return {
    files    => $self->_resolve_import_collisions( \@files ),
    packages => {},
  };

}

########################################################################
sub _matches_import_extension {
########################################################################
  my ( $self, $file, $extensions ) = @_;

  return $TRUE
    if !defined $extensions || $extensions eq q{*};

  if ( ( reftype($extensions) // q{} ) ne 'ARRAY' ) {
    $extensions = [$extensions];
  }

  foreach my $extension ( @{$extensions} ) {
    return $TRUE if $extension eq q{*};

    return $TRUE
      if $file =~ /[.](?:$extension)$/xsm;
  }

  return $FALSE;
}

########################################################################
sub _resolve_import_collisions {
########################################################################
  my ( $self, $files ) = @_;

  my %seen;
  my %destinations;
  my @resolved;

  foreach my $file ( @{$files} ) {
    my $source      = $file->{source};
    my $destination = $file->{destination};

    next if $seen{$destination}{$source}++;

    push @resolved,                        $file;
    push @{ $destinations{$destination} }, $file;
  }

  foreach my $destination ( keys %destinations ) {
    my $conflicts = $destinations{$destination};

    next if @{$conflicts} == 1;

    foreach my $file ( @{$conflicts} ) {
      $file->{original_destination} = $destination;
      $file->{destination}          = $self->_import_error_destination($file);
      $file->{class}                = 'import-error';
      $file->{reason}               = sprintf q{multiple imported files map to '%s'}, $destination;
    }
  }

  my %final_destinations;

  foreach my $file (@resolved) {
    my $destination = $file->{destination};

    if ( exists $final_destinations{$destination} ) {
      croak sprintf "ERROR: multiple import sources resolve to %s\n", $destination;
    }

    $final_destinations{$destination} = $file->{source};
  }

  return \@resolved;
}

########################################################################
sub _add_import_file {
########################################################################
  my ( $self, %args ) = @_;

  my ( $files, $source, $destination, $base_dir, $filename ) = @args{qw(files source destination base_dir filename)};

  $filename //= basename($source);

  $filename =~ s{[.](pm|pl)$}{.$1.in}xsm;

  my $target   = File::Spec->catfile( $destination, $filename );
  my $relative = File::Spec->abs2rel( $source, $base_dir );

  push @{$files},
    {
    source      => $source,
    destination => $target,
    import_root => dirname($relative),
    relative    => basename($relative),
    class       => $destination eq 'lib' ? 'module' : 'file',
    };

  return;
}

########################################################################
sub _excluded_import_path {
########################################################################
  my ( $self, $file, $base_dir, $exclusions ) = @_;

  return $FALSE if !defined $exclusions;

  if ( ( reftype($exclusions) // q{} ) ne 'ARRAY' ) {
    $exclusions = [$exclusions];
  }

  my $relative = File::Spec->abs2rel( $file, $base_dir );
  $relative =~ s{\\}{/}gxsm;

  foreach my $exclude ( @{$exclusions} ) {
    if ( index( $exclude, q{/} ) >= 0 ) {
      my $directory = $exclude;
      $directory =~ s{\A[.]/}{}xsm;
      $directory =~ s{/+\z}{}xsm;

      return $TRUE
        if $relative eq $directory
        || index( $relative, "$directory/" ) == 0;

      next;
    }

    return $TRUE
      if basename($file) =~ /(?:$exclude)$/xsm;
  }

  return $FALSE;
}

########################################################################
sub _test_type {
########################################################################
  my ( $self, $name, $obj, $type ) = @_;

  die "ERROR: $name is not a $type\n"
    if ( reftype($obj) // q{} ) ne $type;

  return;
}

########################################################################
sub _load_import_manifest {
########################################################################
  my ( $self, $import_manifest ) = @_;

  require YAML::Tiny;

  my $yaml = eval { YAML::Tiny->read($import_manifest); };

  croak "ERROR: error reading manifest file: $import_manifest\n$EVAL_ERROR"
    if !$yaml || $EVAL_ERROR;

  return $yaml->[0];
}

########################################################################
sub _validate_import_regexp {
########################################################################
  my ( $self, $expression, $field ) = @_;

  my $regexp = eval {qr/(?:$expression)/xsm};

  if ($EVAL_ERROR) {
    croak sprintf "ERROR: invalid regexp '%s' in import manifest %s:\n%s", $expression, $field, $EVAL_ERROR;
  }

  return;
}

########################################################################
sub _importer_validate_import_destination {
########################################################################
  my ( $self, $path, $field ) = @_;

  die sprintf "ERROR: invalid import %s: empty path\n", $field
    if !defined $path || ref $path || $path eq q{};

  die sprintf "ERROR: invalid import %s: absolute path '%s'\n", $field, $path
    if File::Spec->file_name_is_absolute($path);

  die sprintf "ERROR: invalid import %s: backslash in '%s'\n", $field, $path
    if index( $path, q{\\} ) >= 0;

  my @components = File::Spec->splitdir($path);

  die sprintf "ERROR: invalid import %s: parent traversal in '%s'\n", $field, $path
    if grep { $_ eq q{..} } @components;

  return;
}

1;
