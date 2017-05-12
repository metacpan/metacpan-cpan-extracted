package Alien::SDL;
use strict;
use warnings;
use Alien::SDL::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Find;
use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Temp;
use Capture::Tiny;
use Config;

=head1 NAME

Alien::SDL - building, finding and using SDL binaries

=head1 VERSION

Version 1.446

=cut

our $VERSION = '1.446';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Alien::SDL tries (in given order) during its installation:

=over

=item * When given C<--with-sdl-config> option use specified sdl-config
script to locate SDL libs.

 perl Build.PL --with-sdl-config=/opt/sdl/bin/sdl-config

or using default script name 'sdl-config' by running:

 perl Build.PL --with-sdl-config

B<IMPORTANT NOTE:> Using --with-sdl-config avoids considering any other
build methods; no prompt with other available build options.

=item * Locate an already installed SDL via 'sdl-config' script.

=item * Check for SDL libs in directory specified by SDL_INST_DIR variable.
In this case the module performs SDL library detection via
'$SDL_INST_DIR/bin/sdl-config' script.

 SDL_INST_DIR=/opt/sdl perl ./Build.PL

=item * Download prebuilt SDL binaries (if available for your platform).

=item * Build SDL binaries from source codes (if possible on your system).

=back

Later you can use Alien::SDL in your module that needs to link agains SDL
and/or related libraries like this:

    # Sample Makefile.pl
    use ExtUtils::MakeMaker;
    use Alien::SDL;

    WriteMakefile(
      NAME         => 'Any::SDL::Module',
      VERSION_FROM => 'lib/Any/SDL/Module.pm',
      LIBS         => Alien::SDL->config('libs', [-lAdd_Lib]),
      INC          => Alien::SDL->config('cflags'),
      # + additional params
    );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::SDL> can be used to detect and get
configuration settings from an installed SDL and related libraries.
Based on your platform it offers the possibility to download and
install prebuilt binaries or to build SDL & co. from source codes.

The important facts:

=over

=item * The module does not modify in any way the already existing SDL
installation on your system.

=item * If you reinstall SDL libs on your system you do not need to
reinstall Alien::SDL (providing that you use the same directory for
the new installation).

=item * The prebuild binaries and/or binaries built from sources are always
installed into perl module's 'share' directory.

=item * If you use prebuild binaries and/or binaries built from sources
it happens that some of the dynamic libraries (*.so, *.dll) will not
automaticly loadable as they will be stored somewhere under perl module's
'share' directory. To handle this scenario Alien::SDL offers some special
functionality (see below).

=back

=head1 METHODS

=head2 config()

This function is the main public interface to this module. Basic
functionality works in a very similar maner to 'sdl-config' script:

    Alien::SDL->config('prefix');   # gives the same string as 'sdl-config --prefix'
    Alien::SDL->config('version');  # gives the same string as 'sdl-config --version'
    Alien::SDL->config('libs');     # gives the same string as 'sdl-config --libs'
    Alien::SDL->config('cflags');   # gives the same string as 'sdl-config --cflags'

On top of that this function supports special parameters:

    Alien::SDL->config('ld_shared_libs');

Returns a list of full paths to shared libraries (*.so, *.dll) that will be
required for running the resulting binaries you have linked with SDL libs.

    Alien::SDL->config('ld_paths');

Returns a list of full paths to directories with shared libraries (*.so, *.dll)
that will be required for running the resulting binaries you have linked with
SDL libs.

    Alien::SDL->config('ld_shlib_map');

Returns a reference to hash of value pairs '<libnick>' => '<full_path_to_shlib'>,
where '<libnick>' is shortname for SDL related library like: SDL, SDL_gfx, SDL_net,
SDL_sound ... + some non-SDL shortnames e.g. smpeg, jpeg, png.

NOTE: config('ld_<something>') return an empty list/hash if you have decided to
use SDL libraries already installed on your system. This concerns 'sdl-config'
detection and detection via '$SDL_INST_DIR/bin/sdl-config'.

=head2 check_header()

This function checks the availability of given header(s) when using compiler
options provided by "Alien::SDL->config('cflags')".

    Alien::SDL->check_header('SDL.h');
    Alien::SDL->check_header('SDL.h', 'SDL_net.h');

Returns 1 if all given headers are available, 0 otherwise.

=head2 get_header_version()

Tries to find a header file specified as a param in SDL prefix direcotry and
based on "#define" macros inside this header file tries to get a version triplet.

    Alien::SDL->get_header_version('SDL_mixer.h');
    Alien::SDL->get_header_version('SDL_version.h');
    Alien::SDL->get_header_version('SDL_gfxPrimitives.h');
    Alien::SDL->get_header_version('SDL_image.h');
    Alien::SDL->get_header_version('SDL_mixer.h');
    Alien::SDL->get_header_version('SDL_net.h');
    Alien::SDL->get_header_version('SDL_ttf.h');
    Alien::SDL->get_header_version('smpeg.h');

Returns string like '1.2.3' or undef if not able to find and parse version info.

=head1 BUGS

Please post issues and bugs at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-SDL>

=head1 AUTHOR

    Kartik Thakore
    CPAN ID: KTHAKORE
    Thakore.Kartik@gmail.com
    http://yapgh.blogspot.com

=head1 ACKNOWLEDGEMENTS

    kmx - complete redesign between versions 0.7.x and 0.8.x

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

### get config params
sub config
{
  my $package = shift;
  my @params  = @_;
  return _sdl_config_via_script(@params)      if(Alien::SDL::ConfigData->config('script'));
  return _sdl_config_via_config_data(@params) if(Alien::SDL::ConfigData->config('config'));
}

### get version info from given header file
sub get_header_version {
  my ($package, $header) = @_;
  return unless $header;

  # try to find header
  my $root = Alien::SDL->config('prefix');
  #warn 'Finding in '.$root.'/include';
  my $include = File::Spec->catfile($root, 'include');
  my @files;
  find({ wanted => sub { push @files, rel2abs($_) if /\Q$header\E$/ }, follow => 1, no_chdir => 1, follow_skip => 2 }, $include);
  return unless @files;

  # get version info
  open(DAT, $files[0]) || return;
  my @raw=<DAT>;
  close(DAT);

  # generic magic how to get version major/minor/patchlevel
  my ($v_maj) = grep(/^#define[ \t]+[A-Z_]+?MAJOR[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_maj =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_min) = grep(/^#define[ \t]+[A-Z_]+MINOR[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_min =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_pat) = grep(/^#define[ \t]+[A-Z_]+(PATCHLEVEL|MICRO|RELEASE)[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_pat =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  return if (($v_maj eq '')||($v_min eq '')||($v_pat eq ''));
  return "$v_maj.$v_min.$v_pat";
}

### check presence of header(s) specified as params
sub check_header {
  my ($package, @header) = @_;
  print STDERR "[$package] Testing header(s): " . join(', ', @header);

  require ExtUtils::CBuilder; # PAR packer workaround

  my $config = {};
  if($^O eq 'cygwin') {
    my $ccflags = $Config{ccflags};
    $ccflags    =~ s/-fstack-protector//;
    $config     = { ld => 'gcc', cc => 'gcc', ccflags => $ccflags };
  }

  my $cb = ExtUtils::CBuilder->new( quiet => 1, config => $config );
  my ($fs, $src) = File::Temp::tempfile('aaXXXX', SUFFIX => '.c', UNLINK => 1);
  my $inc = '';
  my $i = 0;
  foreach (@header) {
    @header = (splice(@header, 0, $i) , 'stdio.h', splice(@header, $i)) if $_ eq 'jpeglib.h';
    $i++;
  }
  $inc .= "#include <$_>\n" for @header;
  syswrite($fs, <<MARKER); # write test source code
#if defined(_WIN32) && !defined(__CYGWIN__)
/* GL/gl.h on Win32 requires windows.h being included before */
#include <windows.h>
#endif
$inc
int demofunc(void) { return 0; }

MARKER
  close($fs);
  my $obj;
  my $stdout = '';
  my $stderr = '';
  ($stdout, $stderr) = Capture::Tiny::capture {
    $obj = eval { $cb->compile( source => $src, extra_compiler_flags => Alien::SDL->config('cflags')); };
  };

  if($obj) {
    print STDERR "\n";
    unlink $obj;
    return 1;
  }
  else {
    if( $stderr ) {
      $stderr =~ s/[\r\n]$//;
      $stderr =~ s/^\Q$src\E[\d\s:]*//;
      print STDERR " NOK: ($stderr)\n";
    }
    # on Windows (MSVC) stdout is set, but not stderr
    else {
      $stdout =~ s/[\r\n]$//;
      $stdout =~ s/.+[\r\n]//;
      $stdout =~ s/^\Q$src\E[\(\)\d\s:]*//;
      print STDERR " NOK: ($stdout)\n";
    }

    return 0;
  }
}

### internal functions
sub _sdl_config_via_script
{
  my $param    = shift;
  my @add_libs = @_;
  my $devnull = File::Spec->devnull();
  my $script = Alien::SDL::ConfigData->config('script');
  return unless ($script && ($param =~ /[a-z0-9_]*/i));
  my $val = `$script --$param 2>$devnull`;
  $val =~ s/[\r\n]*$//;
  if($param eq 'cflags') {
    $val .= ' ' . Alien::SDL::ConfigData->config('additional_cflags');
  }
  elsif($param eq 'libs') {
    $val .= ' ' . join(' ', @add_libs) if scalar @add_libs;
    $val .= ' ' . Alien::SDL::ConfigData->config('additional_libs');
  }
  elsif($param =~ /^(ld_shlib_map|ld_shared_libs|ld_paths)$/) {
    $val = Alien::SDL::ConfigData->config('config')->{$param};
  }
  return $val;
}

sub _sdl_config_via_config_data
{
  my $param    = shift;
  my @add_libs = @_;
  my $share_dir = dist_dir('Alien-SDL');
  my $subdir = Alien::SDL::ConfigData->config('share_subdir');
  return unless $subdir;
  my $real_prefix = catdir($share_dir, $subdir);
  return unless ($param =~ /[a-z0-9_]*/i);
  my $val = Alien::SDL::ConfigData->config('config')->{$param};
  return unless $val;
  # handle additional flags
  if($param eq 'cflags') {
    $val .= ' ' . Alien::SDL::ConfigData->config('additional_cflags');
  }
  elsif($param eq 'libs') {
    $val .= ' ' . join(' ', @add_libs) if scalar @add_libs;
    $val .= ' ' . Alien::SDL::ConfigData->config('additional_libs');
  }
  # handle @PrEfIx@ replacement
  if ($param =~ /^(ld_shared_libs|ld_paths)$/) {
    s/\@PrEfIx\@/$real_prefix/g foreach (@{$val});
  }
  elsif ($param =~ /^(ld_shlib_map)$/) {
    while (my ($k, $v) = each %$val ) {
      $val->{$k} =~ s/\@PrEfIx\@/$real_prefix/g;
    }
  }
  else {
    $val =~ s/\@PrEfIx\@/$real_prefix/g;
  }
  return $val;
}

1;
