package Alien::SDL2;
use strict;
use warnings;
use Alien::SDL2::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec;
use File::Find;
use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Temp qw(tempfile);
use Capture::Tiny;
use Config;

=head1 NAME

Alien::SDL2 - building, finding and using SDL2 binaries

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';
$VERSION = eval $VERSION;

my %HAVELIB_CACHE;

=head1 SYNOPSIS

Alien::SDL2 tries (in given order) during its installation:

=over

=item * When given C<--with-sdl2-config> option use specified sdl2-config
script to locate SDL2 libs.

 perl Build.PL --with-sdl2-config=/opt/sdl2/bin/sdl2-config

or using default script name 'sdl2-config' by running:

 perl Build.PL --with-sdl2-config

B<IMPORTANT NOTE:> Using --with-sdl2-config avoids considering any other
build methods; no prompt with other available build options.

=item * Locate an already installed SDL2 via 'sdl2-config' script.

=item * Download prebuilt SDL2 binaries (if available for your platform).

=item * Build SDL2 binaries from source codes (if possible on your system).

=back

Later you can use Alien::SDL2 in your module that needs to link agains SDL2
and/or related libraries like this:

    # Sample Makefile.pl
    use ExtUtils::MakeMaker;
    use Alien::SDL2;

    WriteMakefile(
      NAME         => 'Any::SDL2::Module',
      VERSION_FROM => 'lib/Any/SDL2/Module.pm',
      LIBS         => Alien::SDL2->config('libs', [-lAdd_Lib]),
      INC          => Alien::SDL2->config('cflags'),
      # + additional params
    );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

In short C<Alien::SDL2> can be used to detect and get
configuration settings from an installed SDL2 and related libraries.
Based on your platform it offers the possibility to download and
install prebuilt binaries or to build SDL2 & co. from source codes.

The important facts:

=over

=item * The module does not modify in any way the already existing SDL2
installation on your system.

=item * If you reinstall SDL2 libs on your system you do not need to
reinstall Alien::SDL2 (providing that you use the same directory for
the new installation).

=item * The prebuild binaries and/or binaries built from sources are always
installed into perl module's 'share' directory.

=item * If you use prebuild binaries and/or binaries built from sources
it happens that some of the dynamic libraries (*.so, *.dll) will not
automaticly loadable as they will be stored somewhere under perl module's
'share' directory. To handle this scenario Alien::SDL2 offers some special
functionality (see below).

=back

=head1 METHODS

=head2 config()

This function is the main public interface to this module. Basic
functionality works in a very similar maner to 'sdl2-config' script:

    Alien::SDL2->config('prefix');   # gives the same string as 'sdl2-config --prefix'
    Alien::SDL2->config('version');  # gives the same string as 'sdl2-config --version'
    Alien::SDL2->config('libs');     # gives the same string as 'sdl2-config --libs'
    Alien::SDL2->config('cflags');   # gives the same string as 'sdl2-config --cflags'

On top of that this function supports special parameters:

    Alien::SDL2->config('ld_shared_libs');

Returns a list of full paths to shared libraries (*.so, *.dll) that will be
required for running the resulting binaries you have linked with SDL2 libs.

    Alien::SDL2->config('ld_paths');

Returns a list of full paths to directories with shared libraries (*.so, *.dll)
that will be required for running the resulting binaries you have linked with
SDL2 libs.

    Alien::SDL2->config('ld_shlib_map');

Returns a reference to hash of value pairs '<libnick>' => '<full_path_to_shlib'>,
where '<libnick>' is shortname for SDL2 related library like: SDL2, SDL2_gfx, SDL2_net,
SDL2_sound ... + some non-SDL2 shortnames e.g. smpeg, jpeg, png.

NOTE: config('ld_<something>') return an empty list/hash if you have decided to
use SDL2 libraries already installed on your system. This concerns 'sdl2-config'
detection.

=head2 check_header()

This function checks the availability of given header(s) when using compiler
options provided by "Alien::SDL2->config('cflags')".

    Alien::SDL2->check_header('SDL2.h');
    Alien::SDL2->check_header('SDL2.h', 'SDL2_net.h');

Returns 1 if all given headers are available, 0 otherwise.

=head2 get_header_version()

Tries to find a header file specified as a param in SDL2 prefix direcotry and
based on "#define" macros inside this header file tries to get a version triplet.

    Alien::SDL2->get_header_version('SDL_mixer.h');
    Alien::SDL2->get_header_version('SDL_version.h');
    Alien::SDL2->get_header_version('SDL2_gfxPrimitives.h');
    Alien::SDL2->get_header_version('SDL_image.h');
    Alien::SDL2->get_header_version('SDL_mixer.h');
    Alien::SDL2->get_header_version('SDL_net.h');
    Alien::SDL2->get_header_version('SDL_ttf.h');
    Alien::SDL2->get_header_version('smpeg.h');

Returns string like '1.2.3' or undef if not able to find and parse version info.

=head2 havelib()

Checks the presence of given SDL2 related libraries.

 Alien::SDL2->havelib('SDL2');
 #or
 Alien::SDL2->havelib('SDL2', 'SDL2_image', 'SDL2_mixer');

Parameter(s): One or more SDL2 related lib names - e.g. SDL2, SDL2_mixer, SDL2_image, ...

Returns: 1 if all libs specified as a param are available; 0 otherwise.

=head1 AUTHOR

    Kartik Thakore
    CPAN ID: KTHAKORE
    Thakore.Kartik@gmail.com
    http://yapgh.blogspot.com

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
  return _sdl2_config_via_script(@params)      if(Alien::SDL2::ConfigData->config('script'));
  return _sdl2_config_via_config_data(@params) if(Alien::SDL2::ConfigData->config('config'));
}

### get version info from given header file
sub get_header_version {
  my ($package, $header) = @_;
  return unless $header;

  # try to find header
  my $root = Alien::SDL2->config('prefix');
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
  my ($fs, $src) = tempfile('XXXX', SUFFIX => 'aa.c', UNLINK => 1);
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
    $obj = eval { $cb->compile( source => $src, extra_compiler_flags => Alien::SDL2->config('cflags')); };
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

sub havelib {
  my ($package, @libs) = @_;  
  my %headers = (
        SDL2 => 'SDL_version.h',
        SDL2_mixer => 'SDL_mixer.h',
        SDL2_gfx => 'SDL2_gfxPrimitives.h',
        SDL2_image => 'SDL_image.h',
        SDL2_mixer => 'SDL_mixer.h',
        SDL2_net => 'SDL_net.h',
        SDL2_ttf => 'SDL_ttf.h',
        smpeg => 'smpeg.h',
  );
  for my $l (@libs) {
    next if $HAVELIB_CACHE{$l};
    return 0 unless $headers{$l} && Alien::SDL2->check_header($headers{$l});
    $HAVELIB_CACHE{$l} = 1;
  }
  return 1;
}

### internal functions
sub _sdl2_config_via_script
{
  my $param    = shift;
  my @add_libs = @_;
  my $devnull = File::Spec->devnull();
  my $script = Alien::SDL2::ConfigData->config('script');
  return unless ($script && ($param =~ /[a-z0-9_]*/i));
  my $val = `$script --$param 2>$devnull`;
  $val =~ s/[\r\n]*$//;
  if($param eq 'cflags') {
    $val .= ' ' . Alien::SDL2::ConfigData->config('additional_cflags');
  }
  elsif($param eq 'libs') {
    $val .= ' ' . join(' ', @add_libs) if scalar @add_libs;
    $val .= ' ' . Alien::SDL2::ConfigData->config('additional_libs');
  }
  elsif($param =~ /^(ld_shlib_map|ld_shared_libs|ld_paths)$/) {
    $val = Alien::SDL2::ConfigData->config('config')->{$param};
  }
  return $val;
}

sub _sdl2_config_via_config_data
{
  my $param    = shift;
  my @add_libs = @_;
  my $share_dir = dist_dir('Alien-SDL2');
  my $subdir = Alien::SDL2::ConfigData->config('share_subdir');
  return unless $subdir;
  my $real_prefix = catdir($share_dir, $subdir);
  return unless ($param =~ /[a-z0-9_]*/i);
  my $val = Alien::SDL2::ConfigData->config('config')->{$param};
  return unless $val;
  # handle additional flags
  if($param eq 'cflags') {
    $val .= ' ' . Alien::SDL2::ConfigData->config('additional_cflags');
  }
  elsif($param eq 'libs') {
    $val .= ' ' . join(' ', @add_libs) if scalar @add_libs;
    $val .= ' ' . Alien::SDL2::ConfigData->config('additional_libs');
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
