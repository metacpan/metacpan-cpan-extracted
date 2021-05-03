package Alien::CMake;
use strict;
use warnings;
use Alien::CMake::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Find;
use File::Spec::Functions qw(catdir catfile rel2abs);

=head1 NAME

Alien::CMake - Build and make available CMake library - L<http://cmake.org/>

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

Alien::CMake during its installation does one of the following:

=over

=item * Builds I<CMake> binaries from source codes and installs dev 
files (headers: *.h, static library: *.a) into I<share>
directory of Alien::CMake distribution.

=back

Later you can use Alien::CMake in your module that needs to link with I<libode>
like this:

    # Sample Build.pl
    use Module::Build;
    use Alien::CMake;

    my $build = Module::Build->new(
      module_name => 'Any::CMake::Module',
      # + other params
      build_requires => {
                    'Alien::CMake' => 0,
                    # + others modules
      },
      configure_requires => {
                    'Alien::CMake' => 0,
                    # + others modules
      },
      extra_compiler_flags => Alien::CMake->config('cflags'),
      extra_linker_flags   => Alien::CMake->config('libs'),
    )->create_build_script;

NOTE: Alien::CMake is required only for building not for using 'Any::CMake::Module'.

=head1 DESCRIPTION

Please consider using L<Alien::cmake3> instead.  It uses newer Alien
technology and is more reliable.  In particular, this module will download
very old binaries for some platforms (some from the 2.x series).  In
addition L<Alien::cmake3> will build from source if binaries are not
available for your platform.  Also L<Alien::cmake3> integrates more
naturally with L<alienfile> and L<Alien::Build>.

In short C<Alien::CMake> can be used to detect and get configuration
settings from an already installed CMake. It offers also an option to
download CMake source codes and build binaries from scratch.

=head1 METHODS

=head2 config()

This function is the main public interface to this module:

    Alien::CMake->config('prefix');
    Alien::CMake->config('version');
    Alien::CMake->config('libs');
    Alien::CMake->config('cflags');

=head2 bin_dir()

For compatability with L<Alien::Base>, this will return the path containing C<cmake>
or empty list if it is already in the C<PATH>.

=head1 BUGS

Please post issues and bugs at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-CMake>

=head1 AUTHOR

KMX, E<lt>kmx at cpan.orgE<gt>,
FROGGS, E<lt>froggs at cpan.orgE<gt>,
plicease E<lt>plicease at cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

### get config params
sub config
{
  my ($package, $param) = @_;
  return _cmake_config_via_config_data($param) if(Alien::CMake::ConfigData->config('config'));
}

sub set_path
{
  my $path_sep = ':';
  if($^O eq 'MSWin32')
  {
    $path_sep  = ';';
    my @paths  = split($path_sep, $ENV{'PATH'});
    my @_paths = ();
    my $i = 0;
    foreach (@paths)
    {
      push(@_paths, $_) unless -e "$_/sh.exe"; # cmake throws a warning when sh.exe is in path when using mingw32
    }

    unless(Alien::CMake::ConfigData->config('script'))
    {
      unshift(@_paths, Alien::CMake->config('bin'));
    }

    $ENV{'PATH'} = join($path_sep, @_paths);
  }
  elsif(!Alien::CMake::ConfigData->config('script'))
  {
    $ENV{'PATH'} = join($path_sep, Alien::CMake->config('bin'), $ENV{'PATH'});
  }

  return $ENV{'PATH'};
}

### internal functions
sub _cmake_config_via_config_data
{
  my ($param)     = @_;
  my $real_prefix = '';
  my $subdir      = Alien::CMake::ConfigData->config('share_subdir');
  if(Alien::CMake::ConfigData->config('script'))
  {
    $real_prefix = $subdir;
  }
  else
  {
    my $share_dir = dist_dir('Alien-CMake');
    return unless $subdir;
    $real_prefix = catdir($share_dir, $subdir);
  }

  return unless ($param =~ /[a-z0-9_]*/i);
  my $val = Alien::CMake::ConfigData->config('config')->{$param};
  return unless $val;
  # handle @PrEfIx@ replacement
  $val =~ s/\@PrEfIx\@/$real_prefix/g;
  return $val;
}

sub bin_dir
{
  !Alien::CMake::ConfigData->config('script')
    ? (Alien::CMake->config('bin'))
    : ();
}

1;
