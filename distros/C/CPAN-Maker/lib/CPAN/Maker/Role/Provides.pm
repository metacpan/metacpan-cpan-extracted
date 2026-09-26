package CPAN::Maker::Role::Provides;

use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use File::Find;
use File::Process qw(process_file);
use Scalar::Util qw(reftype);

use CLI::Simple::Utils qw(slurp);
use CLI::Simple::Constants qw(:booleans);

use Role::Tiny;

requires qw(get_module_version);

########################################################################
sub create_provides {
########################################################################
  my ( $self, %args ) = @_;

  my $path = $args{path} // 'lib';
  my $file = $args{file} // 'provides';

  my @provides;

  if ( -d $path ) {
    find(
      { follow   => $TRUE,
        no_chdir => $TRUE,
        wanted   => sub {
          my $module_file = $File::Find::name;

          return if !-f $module_file;
          return if $module_file !~ /[.]pm$/xsm;

          my $module = $module_file;
          $module =~ s{^\Q$path\E/?}{}xsm;
          $module =~ s{/}{::}gxsm;
          $module =~ s{[.]pm$}{}xsm;

          my $module_version = $self->get_module_version( $module, $path );

          my $provided_module = $module_version->{module} // $module;

          my $version = $module_version->{version} // 'undef';

          push @provides, sprintf '%s %s', $provided_module, $version;

          return;
        },
      },
      $path
    );
  }

  $self->write_provides(
    provides => \@provides,
    file     => $file,
  );

  return $file;
}

########################################################################
sub get_provides {
########################################################################
  my ( $self, %args ) = @_;

  my $file     = $args{file};
  my $work_dir = $args{work_dir};

  my %provides;
  my @missing;

  return %provides
    if !$file || !-e $file;

  process_file(
    $file,
    chomp            => $TRUE,
    skip_blank_lines => $TRUE,
    prefix           => 'lib',
    process          => sub {
      my $line = pop @_;
      my $args = pop @_;

      return ()
        if !$line;

      my ( $module, $provided_version ) = split /\s+/xsm, $line, 2;

      return ()
        if !$module;

      $provided_version //= 'undef';

      my $prefix       = $args->{prefix};
      my $include_path = $prefix;

      if ($work_dir) {
        $include_path = sprintf '%s/%s', $work_dir, $prefix;
      }

      my $module_version = $self->get_module_version( $module, $include_path );

      my $provided_module = $module_version->{module} // $module;

      if ( !$module_version->{file} ) {
        push @missing,
          {
          module  => $module,
          version => $provided_version,
          };

        return $provided_module;
      }

      $provides{$provided_module} = {
        file    => sprintf( '%s/%s', $prefix, $module_version->{file}, ),
        version => $provided_version,
      };

      return $provided_module;
    }
  );

  if (@missing) {
    my $dir = $work_dir ? sprintf( '%s/lib', $work_dir ) : 'lib';

    my @file_list;

    if ( -d $dir ) {
      find(
        { no_chdir => $TRUE,
          wanted   => sub {
            my $module_file = $File::Find::name;
            return if !-f $module_file;
            return if $module_file !~ /[.]pm$/xsm;
            push @file_list, $module_file;

            return;
          },
        },
        $dir
      );
    }

    local @INC = ( $dir, @INC );

    foreach my $missing (@missing) {
      my $module           = $missing->{module};
      my $provided_version = $missing->{version};

      foreach my $module_file (@file_list) {
        my $text = slurp($module_file);

        next
          if $text !~ /^package\s+\Q$module\E;/xsm;

        # Remove POD before confirming the package declaration so a
        # documented package name does not produce a false positive.
        $text =~ s/^=pod(.*?)=cut//xsmg;

        next
          if $text !~ /^package\s+\Q$module\E;/xsm;

        my $version = $provided_version;

        if ( !defined $version || $version eq 'undef' ) {
          $version = eval {
            local $SIG{__WARN__} = sub { };

            require $module_file;

            no strict 'refs'; ## no critic

            return ${ $module . '::VERSION' };
          };

          $version //= 'undef';
        }

        my $rel_path = $module_file;

        if ($work_dir) {
          $rel_path =~ s{^\Q$work_dir\E/}{}xsm;
        }

        $provides{$module} = {
          file    => $rel_path,
          version => $version,
        };

        last;
      }
    }
  }

  return %provides;
}

########################################################################
sub _write_provides {
########################################################################
  my ( $self, $fh, $provides ) = @_;

  croak "provides must be an array\n"
    if !defined $provides || !ref $provides || reftype($provides) ne 'ARRAY';

  foreach my $provide ( sort @{$provides} ) {
    next if !$provide;

    my ( $module, $version ) = split /\s+/xsm, $provide, 2;

    if ( !defined $version || $version eq q{} ) {
      $version = 'undef';
    }

    print {$fh} sprintf "%s %s\n", $module, $version;
  }

  return;
}

########################################################################
sub write_provides {
########################################################################
  my ( $self, %args ) = @_;

  my $provides = $args{provides};
  my $file     = $args{file} // 'provides';

  return
    if !$provides;

  croak "provides must be an array\n"
    if !ref $provides || reftype($provides) ne 'ARRAY';

  open my $fh, '>', $file
    or croak "could not open '$file' for writing: $OS_ERROR\n";

  $self->_write_provides( $fh, $provides );

  close $fh
    or croak "could not close '$file': $OS_ERROR\n";

  return;
}

1;
