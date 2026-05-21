package CPAN::Maker::Role::FileUtils;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(slurp);
use CPAN::Maker::Utils;
use Cwd qw(getcwd);
use Data::Dumper;
use File::Basename qw(fileparse);
use File::Find qw(find);
use File::Temp qw(tempfile);
use Scalar::Util qw(reftype);

use Role::Tiny;

our $VERSION = '1.9.1';

########################################################################
sub fetch_file_list {
########################################################################
  my ( $self, %args ) = @_;

  my ( $file_list, $destdir, $project_root, $exclude ) = @args{qw(file_list destination project_root exclude)};

  my @expanded_list;
  my @exclude = ( @{ $exclude // [] }, grep {/^!/xsm} @{$file_list} );

  foreach (@exclude) {
    s/^!//xsm;
  }

  foreach my $f ( grep { !/^!/xsm } @{$file_list} ) {
    my $fqp = sprintf '%s/%s', $project_root, $f;

    $self->get_logger->debug( Dumper( [ 'fetch_file_list:', $fqp ] ) );

    # no recurse of directories!
    my $cwd = getcwd();

    if ( -d $fqp ) {
      eval {
        find(
          { follow => $TRUE,
            wanted => sub {
              return
                if /^[.]/xsm || -d $_;

              die 'done'
                if getcwd() ne $fqp;

              my $name = $_;

              foreach my $e (@exclude) {

                if ( $e =~ /^\/([^\/]+)\/$/xsm ) {
                  my $pat = qr/$1/xsm;

                  if ( $name =~ /$pat/ ) {
                    return;
                  }
                }

                return
                  if $e eq $name;
              }

              push @expanded_list, "$File::Find::name $destdir/$name";
            }
          },
          $fqp
        );
      };

      chdir $cwd;

      # remove project root since bash script will add it
      for (@expanded_list) {
        s/^$project_root//xsm;
      }
    }
    else {
      # the intent is to cp files to root of distribution (not
      # to install the files during package installation...the
      # exception being if items are installed into share
      # directory
      die "ERROR: missing file in list ($fqp) - check your `extra-files` section\n"
        if !-e $fqp;

      my ( $name, $path, $ext ) = fileparse( $fqp, qr/[.][^.]+/xsm );
      push @expanded_list, sprintf '%s %s/%s%s', $f, $destdir, $name, $ext;
    }
  }

  return @expanded_list;
}

########################################################################
sub write_extra_files {
########################################################################
  my ( $self, %params ) = @_;

  $self->get_logger->debug('writing extra-files');

  my ( $extra_files, $extra, $project_root ) = @params{qw(extra_files extra project_root)};

  my %args = %{ $params{args} };

  $extra_files //= [];

  die "ERROR: extra-files must be an array!\n" . Dumper( [ $extra_files, \%params ] )
    if !is_array($extra_files);

  my $extra_files_path = $extra || 'extra-files';

  my @file_list;

  foreach my $e ( @{$extra_files} ) {
    $self->get_logger->debug( Dumper( [ extra => $e ] ) );

    if ( !ref $e ) {  # file or directory
      push @file_list,
        $self->fetch_file_list(
        file_list    => [$e],
        destination  => $EMPTY,
        project_root => $project_root,
        );
    }
    elsif ( is_hash($e) ) {
      # if the extra-files entry is a hash, then the key of that hash
      # represents the destination directory.  The value must be an
      # array of scalars that can represent individual files within
      # the project or whole directories within the project that
      # should be written to the destination directory
      #
      # DO NOT DO THIS...
      # extra-files:
      #   - t: foo.t
      #
      # DO THIS INSTEAD...
      # extra-files:
      #   - t:
      #       - foo.t
      #
      #
      my ($destdir) = keys %{$e};
      my $file_list = $e->{$destdir};

      die "ERROR: directory args for extra-files must be an array!\n"
        if !is_array($file_list);

      push @file_list,
        $self->fetch_file_list(
        file_list    => $file_list,
        destination  => $destdir,
        project_root => $project_root,
        );

    }
  }

  return %args
    if !@file_list;

  open my $fh, '>', $extra_files_path
    or die "ERROR: could not append to $extra_files_path\n";

  foreach my $f (@file_list) {
    print {$fh} "$f\n";
  }

  close $fh
    or die "ERROR: could not close $extra_files_path\n";

  $args{f} = $extra_files_path;

  return %args;
}

########################################################################
sub parse_path {
########################################################################
  my ( $self, $project_root, $path, %args ) = @_;

  if ($path) {
    if ( $path->{recurse}
      && $path->{recurse} =~ /(yes|no)/ixsm ) {
      $args{R} = $path->{recurse};
    }
    elsif ( $path->{recurse} ) {
      die "ERROR: use only yes or no for 'recurse' option\n";
    }

    # -l
    if ( $path->{'pm-module'} ) {
      $args{l} = $path->{'pm-module'};
    }

    if ( $path->{'exclude-files'} ) {
      $args{E} = $path->{'exclude-files'};
    }

    # -e
    if ( $path->{'exe-files'} ) {
      if ( $self->check_path( $project_root, $path->{'exe-files'}, 'exe-files' ) ) {
        $args{e} = $path->{'exe-files'};
      }
    }

    # -S
    if ( $path->{scripts} ) {
      if ( $self->check_path( $project_root, $path->{scripts}, 'scripts' ) ) {
        $args{S} = $path->{scripts};
      }
    }

    # -t
    if ( $path->{tests} ) {
      if ( $self->check_path( $project_root, $path->{tests}, 'tests' ) ) {
        $args{t} = $path->{tests};
      }
    }
  }

  return %args;
}

########################################################################
sub check_path {
########################################################################
  my ( $self, $project_root, $path, $option_name ) = @_;

  die sprintf "ERROR: '%s' must be a scalar representing a path not %s\n", $option_name, reftype($path)
    if ref $path;

  my $exists = $path =~ /^\//xsm ? -d $path : -d "$project_root/$path";

  if ( !$exists ) {
    warn "WARNING: ** `$path` does not exist or is inaccessible.\n";
    warn "WARNING: ** paths should be absolute or relative to $project_root\n";
    warn "WARNING: ** Consider removing entry from your buildspec.yml file if this is expected.\n";
    return $FALSE;
  }

  return $TRUE;
}

########################################################################
sub create_temp_filelist {
########################################################################
  my ( $self, $project_root, $filelist ) = @_;

  if ( ref $filelist && reftype($filelist) eq 'ARRAY' ) {
    my ( $fh, $filename ) = tempfile( 'make-cpan-dist-XXXXX', TMPDIR => $TRUE );

    foreach my $file ( @{$filelist} ) {
      my $path = $file =~ /^\//xsm ? $file : "$project_root/$file";

      die "ERROR: no such file $path\n"
        if !-e $path;

      print {$fh} "$path\n";
    }

    close $fh;

    return $filename;
  }
  elsif ( !ref $filelist ) {
    return $filelist
      if -e $filelist;

    die "ERROR: no such file $filelist\n";
  }
}

########################################################################
sub fetch_relative_filelist {
########################################################################
  my ( $self, $project_root, $file ) = @_;

  my @file_list = grep { !!$_ } split /\n/xsm, slurp($file);

  foreach (@file_list) {
    s/$project_root\/?//xsm;
  }

  return \@file_list;
}

1;

__END__
