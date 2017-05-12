package My::Utility;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(check_config_script check_prebuilt_binaries check_prereqs_libs check_prereqs_tools find_SDL2_dir find_file check_header
                    sed_inplace get_dlext $inc_lib_candidates $source_packs);
use Config;
use ExtUtils::CBuilder;
use File::Spec::Functions qw(splitdir catdir splitpath catpath rel2abs);
use File::Find qw(find);
use File::Which;
use File::Copy qw(cp);
use Cwd qw(realpath);

our $cc                 = $Config{cc};
our $inc_lib_candidates = {
  '/usr/local/include'       => '/usr/local/lib',
  '/usr/include'             => '/usr/lib',
  '/usr/X11R6/include'       => '/usr/X11R6/lib',
  '/usr/local/include/smpeg' => '/usr/local/lib',
};
$inc_lib_candidates->{'/usr/pkg/include/smpeg'} = '/usr/local/lib'            if -f '/usr/pkg/include/smpeg/smpeg.h';
$inc_lib_candidates->{'/usr/include/smpeg'}     = '/usr/lib'                  if -f '/usr/include/smpeg/smpeg.h';
$inc_lib_candidates->{'/usr/X11R6/include'}     = '/usr/X11R6/lib'            if -f '/usr/X11R6/include/GL/gl.h';
$inc_lib_candidates->{'/usr/X11R7/include'}     = '/usr/X11R7/lib'            if -f '/usr/X11R7/include/GL/gl.h';
$inc_lib_candidates->{'/usr/X11R7/include'}     = '/usr/X11R7/lib'            if -f '/usr/X11R7/include/freetype2/freetype/freetype.h';
$inc_lib_candidates->{'/usr/X11R7/include'}     = '/usr/X11R7/lib'            if -f '/usr/X11R7/include/fontconfig/fontconfig.h';
$inc_lib_candidates->{'/usr/include/ogg'}       = '/usr/lib/x86_64-linux-gnu' if -f '/usr/lib/x86_64-linux-gnu/libogg.so';
$inc_lib_candidates->{'/usr/include/vorbis'}    = '/usr/lib/x86_64-linux-gnu' if -f '/usr/lib/x86_64-linux-gnu/libvorbis.so';
$inc_lib_candidates->{'/usr/include'}           = '/usr/lib64'                if -e '/usr/lib64' && $Config{'myarchname'} =~ /64/;
$inc_lib_candidates->{'/usr/include'}           = ['/usr/lib64', '/usr/lib']  if -e '/usr/lib64' && -e '/usr/lib' && $Config{'myarchname'} =~ /64/;

$inc_lib_candidates->{$ENV{SDL2_INC}}           = $ENV{SDL2_LIB}              if exists $ENV{SDL2_LIB} && exists $ENV{SDL2_INC};

#### packs with prebuilt binaries
# the order matters, we offer binaries to user in the same order (1st = preffered)
my $prebuilt_binaries = [
    {
      title    => "Binaries Win/32bit SDL2 (20130305) RECOMMENDED\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf)",
      url      => [
        'http://strawberryperl.com/package/kmx/sdl/32bit_SDL2_20130305.zip',
      ],
      sha1sum  => 'e77e5f04339d60871e9b79f66ac1bca4996648a7',
      match    => sub { $Config{archname} =~ /^MSWin32-x86-/ && $Config{cc} =~ /gcc/ },
    },
    {
      title    => "Binaries Win/64bit SDL2 (20130305) RECOMMENDED\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf)",
      url      => [
        'http://strawberryperl.com/package/kmx/sdl/64bit_SDL2_20130305.zip',
      ],
      sha1sum  => 'f4d9b5e933029571ebbc1e323f504300da7988bc',
      match    => sub { $Config{archname} =~ /^MSWin32-x64-/ && $Config{cc} =~ /gcc/ },
    },
 ];

#### tarballs with source codes
our $source_packs = [
  {
    title   => "Source code build\n    ",
    members => [
      {
        pack => 'z',
        version => '1.2.8',
        dirname => 'zlib-1.2.8',
        url => [
          'http://zlib.net/zlib-1.2.8.tar.gz'
        ],
        sha1sum  => 'a4d316c404ff54ca545ea71a27af7dbc29817088',
        patches => [],
        prereq_libs => [],
      },
      {
        pack => 'jpeg',
        version => '9',
        dirname => 'jpeg-9',
        url => [
          'http://www.ijg.org/files/jpegsrc.v9.tar.gz'
        ],
        sha1sum  => '724987e7690ca3d74d6ab7c1f1b6854e88ca204b',
        patches => [],
        prereq_libs => [],
      },
      {
        pack => 'tiff',
        version => '4.0.3',
        dirname => 'tiff-4.0.3',
        url => [
          'ftp://ftp.remotesensing.org/pub/libtiff/tiff-4.0.3.tar.gz',
        ],
        sha1sum  => '652e97b78f1444237a82cbcfe014310e776eb6f0',
        patches => ['libtiff.4.0.3.tiffio.h.patch'],
        prereq_libs => [],
      },
      {
        pack => 'png',
        version => '1.6.3',
        dirname => 'libpng-1.6.3',
        url => [
          'http://downloads.sourceforge.net/libpng/libpng-1.6.3.tar.gz',
        ],
        sha1sum  => 'b8b7b911909c09d71324536aaa7750104d170c77',
        patches => ['libpng-1.6.3-hack.patch'],
        prereq_libs => ['z'],
      },
      {
        pack => 'freetype',
        version => '2.5.0.1',
        dirname => 'freetype-2.5.0.1',
        url => [
          'http://www.mirrorservice.org/sites/download.savannah.gnu.org/releases/freetype/freetype-2.5.0.1.tar.gz',
        ],
        sha1sum  => '2d539b375688466a8e7dcc4260ab21003faab08c',
        patches => [],
        prereq_libs => ['SDL2', 'freetype'],
      },
      {
        pack => 'SDL2',
        version => '2.0.0',
        dirname => 'SDL2-2.0.0',
        url => [
          'http://www.libsdl.org/release/SDL2-2.0.0.tar.gz',
          'http://strawberryperl.com/package/kmx/sdl/src/SDL2-2.0.0.tar.gz',
        ],
        sha1sum  => 'a907eb5203abad6649c1eae0120d96c0a1931350',
        patches => [],
        prereq_libs => ['pthread'],
      },
      {
        pack => 'SDL2_image',
        version => '2.0.0',
        dirname => 'SDL2_image-2.0.0',
        url => [
          'http://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.0.tar.gz',
          'http://strawberryperl.com/package/kmx/sdl/src/SDL2_image-2.0.0.tar.gz',
        ],
        sha1sum  => '20b1b0db9dd540d6d5e40c7da8a39c6a81248865',
        patches => [],
        prereq_libs => ['SDL2', 'jpeg', 'tiff', 'png'],
      },
      {
        pack => 'ogg',
        version => '1.3.1',
        dirname => 'libogg-1.3.1',
        url => [
          'http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz',
          'http://strawberryperl.com/package/kmx/sdl/src/libogg-1.3.1.tar.gz',
        ],
        sha1sum  => '270685c2a3d9dc6c98372627af99868aa4b4db53',
        patches => [],
        prereq_libs => [],
      },
      {
        pack => 'vorbis',
        version => '1.3.3',
        dirname => 'libvorbis-1.3.3',
        url => [
          'http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz',
          'http://strawberryperl.com/package/kmx/sdl/src/libvorbis-1.3.3.tar.gz',
          'http://froggs.de/libsdl/libvorbis-1.3.3.tar.gz',
        ],
        sha1sum  => '8dae60349292ed76db0e490dc5ee51088a84518b',
        patches => [
          'libvorbis-1.3.3-configure.patch',
        ],
        prereq_libs => [],
      },
      {
        pack => 'SDL2_mixer',
        version => '2.0.0',
        dirname => 'SDL2_mixer-2.0.0',
        url => [
          'http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.0.tar.gz',
          'http://strawberryperl.com/package/kmx/sdl/src/SDL2_mixer-2.0.0.tar.gz',
        ],
        sha1sum  => '9ed975587f09a1776ba9776dcc74a58e695aba6e',
        patches => [],
        prereq_libs => ['SDL2', 'ogg', 'vorbis', 'smpeg'],
      },
      {
        pack => 'SDL2_ttf',
        version => '2.0.12',
        dirname => 'SDL2_ttf-2.0.12',
        url => [
          'http://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.12.tar.gz',
          'http://strawberryperl.com/package/kmx/sdl/src/SDL2_ttf-2.0.12.tar.gz',
        ],
        sha1sum  => '542865c604fe92d2f26000428ef733381caa0e8e',
        patches => [],
        prereq_libs => ['freetype'],
      },
      {
        pack => 'SDL2_gfx',
        version => '20130301-hg',
        dirname => 'SDL2_gfx-svn20130301',
        url => [
          'http://strawberryperl.com/package/kmx/sdl/src/SDL2_gfx-svn20130301.tar.gz',
        ],
        sha1sum  => '3ba18531d34f442ba9f4f6d84feb353dfb9c8130',
        patches => [],
        prereq_libs => ['SDL2'], 
      },
      {
        pack => 'smpeg',
        version => '20130301-svn',
        dirname => 'libsmpeg-svn20130301',
        url => [
          'http://strawberryperl.com/package/kmx/sdl/src/libsmpeg-svn20130301.tar.gz',
        ],
        sha1sum  => 'bba9f1f5313bf02bd4e5ee9f7b7d7459086647a1',
        patches => [],
        prereq_libs => ['SDL'],
      },
    ],
  },
];

sub check_config_script {
  my $script = shift || 'sdl2-config';
  print "checking for config script... ";
  my $devnull = File::Spec->devnull();
  my $version = `$script --version 2>$devnull`;
  if($? >> 8) {
    print "no\n";
    return;
  }
  my $prefix = `$script --prefix 2>$devnull`;
  if($? >> 8) {
    print "no\n";
    return;
  }
  $version =~ s/[\r\n]+$//;
  $prefix  =~ s/[\r\n]+$//;
  $prefix = rel2abs($prefix);
  print "yes, $script\n";
  #returning HASHREF
  return {
    title     => "Already installed SDL2 ver=$version path=$prefix",
    buildtype => 'use_config_script',
    script    => $script,
    prefix    => $prefix,
  };
}

sub find_dll_lib_inc {
 my ($inc, $ld, $lib, $dlext, $header ) = @_;
    my $found_dll          = '';
    my $found_lib          = '';
    my $found_inc          = '';
     
    ($found_dll) = find_file($ld, qr/[\/\\]lib\Q$lib\E[\-\d\.]*\.($dlext[\d\.]*|so|dll)$/);
      $found_dll   = $1 if $found_dll && $found_dll =~/^(.+($dlext|so|dll))/ && -e $1;

    ($found_inc) = find_file($inc,  qr/[\/\\]\Q$header\E[\-\d\.]*\.h$/);
    ($found_lib) = find_file($ld, qr/[\/\\]lib\Q$lib\E[\-\d\.]*\.($dlext[\d\.]*|a|dll.a)$/);

  return ( $found_dll, $found_lib, $found_inc );
}

sub check_prebuilt_binaries
{
  print "checking for prebuilt binaries... ";
  my @good = ();
  foreach my $b (@{$prebuilt_binaries}) {
    if ($b->{match} && &{$b->{match}}) {
      $b->{buildtype} = 'use_prebuilt_binaries';
      delete $b->{match}; #avoid later warnings
      push @good, $b;
    }
  }
  scalar(@good)
    ? print "yes, " . scalar(@good) . " option(s)\n"
    : print "no\n";
  #returning ARRAY of HASHREFs (sometimes more than one value)
  return \@good;
}

sub check_prereqs_libs {
  my @libs = @_;
  my $ret  = 1;

  foreach my $lib (@libs) {
    print "checking for $lib... ";
    my $found_dll          = '';
    my $found_lib          = '';
    my $found_inc          = '';
    my $header_map         = {
      'z'       => 'zlib',
      'jpeg'    => 'jpeglib',
      'vorbis'  => 'vorbisenc',
      'SDL2_gfx' => 'SDL2_gfxPrimitives',
      'SDL2'     => 'SDL_version',
    };
    my $header             = (defined $header_map->{$lib}) ? $header_map->{$lib} : $lib;
    my $dlext = get_dlext();
    foreach (keys %$inc_lib_candidates) {
      my $inc = $_;
      my $ld = $inc_lib_candidates->{$inc};
      next unless -d $_ && (-d $ld || ref $ld eq 'ARRAY');
	if( ref $ld eq 'ARRAY' ) {
		   my $ld_size = scalar( @{ $ld } );
		   foreach ( 0..$ld_size ) {
			next unless (defined $ld->[$_] && -d $ld->[$_]);
			  ($found_dll, $found_lib, $found_inc) = find_dll_lib_inc($inc, $ld->[$_], $lib, $dlext, $header );
			last if $found_lib;
		}
	}
	else {
	  ($found_dll, $found_lib, $found_inc) = find_dll_lib_inc($inc, $ld, $lib, $dlext, $header,);
	}
      last if $found_lib && $found_inc;
    }

    if($found_lib && $found_inc) {
      print "yes\n";
      $ret &= 1;
    }
    else {
      print "no\n";
      $ret = 0;
    }
  warn "###ERROR### Can't find $lib, will not compile libSDL2" if ($lib =~ 'pthread' && $ret == 0);

    if( scalar(@libs) == 1 ) {
      return $ret
        ? [(get_header_version($found_inc) || 'found'), $found_dll]
        : [0, undef];
    }
  }

  return $ret;
}

sub check_prereqs {
  my $bp  = shift;
  my $ret = 1;
  $ret   &= check_prereqs_libs(@{$bp->{prereq_libs}}) if defined $bp->{prereq_libs};

  return $ret;
}

sub check_prereqs_tools {
  my @tools = @_;
  my $ret   = 1;

  foreach my $tool (@tools) {

    if((File::Which::which($tool) && -x File::Which::which($tool))
    || ('pkg-config' eq $tool && defined $ENV{PKG_CONFIG} && $ENV{PKG_CONFIG}
                              && File::Which::which($ENV{PKG_CONFIG})
                              && -x File::Which::which($ENV{PKG_CONFIG}))) {
      $ret &= 1;
    }
    else {
      $ret = 0;
    }
  }

  return $ret;
}

sub find_file {
  my ($dir, $re) = @_;
  my @files;
  $re ||= qr/.*/;
  {
    #hide warning "Can't opendir(...): Permission denied - fix for http://rt.cpan.org/Public/Bug/Display.html?id=57232
    no warnings;
    find({ wanted => sub { push @files, rel2abs($_) if /$re/ }, follow => 1, no_chdir => 1 , follow_skip => 2}, $dir);
  };
  return @files;
}

sub find_SDL2_dir {
  my $root = shift;
  my ($version, $prefix, $incdir, $libdir);
  return unless $root;

  # try to find SDL_version.h
  my ($found) = find_file($root, qr/SDL_version\.h$/i ); # take just the first one
  return unless $found;

  # get version info
  open(DAT, $found) || return;
  my @raw=<DAT>;
  close(DAT);
  my ($v_maj) = grep(/^#define[ \t]+SDL_MAJOR_VERSION[ \t]+[0-9]+/, @raw);
  $v_maj =~ s/^#define[ \t]+SDL_MAJOR_VERSION[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_min) = grep(/^#define[ \t]+SDL_MINOR_VERSION[ \t]+[0-9]+/, @raw);
  $v_min =~ s/^#define[ \t]+SDL_MINOR_VERSION[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_pat) = grep(/^#define[ \t]+SDL_PATCHLEVEL[ \t]+[0-9]+/, @raw);
  $v_pat =~ s/^#define[ \t]+SDL_PATCHLEVEL[ \t]+([0-9]+)[.\r\n]*$/$1/;
  return if (($v_maj eq '')||($v_min eq '')||($v_pat eq ''));
  $version = "$v_maj.$v_min.$v_pat";
  
  # get prefix dir
  my ($v, $d, $f) = splitpath($found);
  my @pp = reverse splitdir($d);
  shift(@pp) if(defined($pp[0]) && $pp[0] eq '');
  shift(@pp) if(defined($pp[0]) && $pp[0] eq 'SDL2');
  if(defined($pp[0]) && $pp[0] eq 'include') {
    shift(@pp);
    @pp = reverse @pp;
    return (
      $version,
      catpath($v, catdir(@pp), ''),
      catpath($v, catdir(@pp, 'include'), ''),
      catpath($v, catdir(@pp, 'lib'), ''),
    );
  }
}

sub check_header {
  my ($cflags, @header) = @_;
  print STDERR "Testing header(s): " . join(', ', @header) . "\n";
  my $cb = ExtUtils::CBuilder->new(quiet => 1);
  my ($fs, $src) = File::Temp->tempfile( 'XXXX', SUFFIX => 'aa.c', UNLINK => 1);
  my $inc = '';
  $inc .= "#include <$_>\n" for @header;
  syswrite($fs, <<MARKER); # write test source code
#if defined(_WIN32) && !defined(__CYGWIN__)
#include <stdio.h>
/* GL/gl.h on Win32 requires windows.h being included before */
#include <windows.h>
#endif
$inc
int demofunc(void) { return 0; }

MARKER
  close($fs);
  my $obj = eval { $cb->compile( source => $src, extra_compiler_flags => $cflags); };
  if($obj) {
    unlink $obj;
    return 1;
  }
  else {
    print STDERR "###TEST FAILED### for: " . join(', ', @header) . "\n";
    return 0;
  }
}

sub sed_inplace {
  # we expect to be called like this:
  # sed_inplace("filename.txt", 's/0x([0-9]*)/n=$1/g');
  my ($file, $re) = @_;
  if (-e $file) {
    cp($file, "$file.bak") or die "###ERROR### cp: $!";
    open INPF, "<", "$file.bak" or die "###ERROR### open<: $!";
    open OUTF, ">", $file or die "###ERROR### open>: $!";
    binmode OUTF; # we do not want Windows newlines
    while (<INPF>) {
     eval( "$re" );
     print OUTF $_;
    }
    close INPF;
    close OUTF;
  }
}

sub get_dlext {
  if($^O =~ /darwin/) { # there can be .dylib's on a mac even if $Config{dlext} is 'bundle'
    return 'so|dylib|bundle';
  }
  elsif( $^O =~ /cygwin/) {
    return 'la';
  }
  else {
    return $Config{dlext};
  }
}

sub get_header_version {
  my $file = shift;
  # get version info
  open(DAT, $file) || return;
  my @raw = <DAT>;
  close(DAT);

  # generic magic how to get version major/minor/patchlevel
  my ($v_maj) = grep(/^#define[ \t]+[A-Z_]+?MAJOR[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_maj      = '' unless defined $v_maj;
  $v_maj      =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_min) = grep(/^#define[ \t]+[A-Z_]+MINOR[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_min      = '' unless defined $v_min;
  $v_min      =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_pat) = grep(/^#define[ \t]+[A-Z_]+(PATCHLEVEL|MICRO|RELEASE)[A-Z_]*[ \t]+[0-9]+/, @raw);
  $v_pat      = '' unless defined $v_pat;
  $v_pat      =~ s/^#define[ \t]+[A-Z_]+[ \t]+([0-9]+)[.\r\n]*$/$1/;
  if(($v_maj eq '')||($v_min eq '')||($v_pat eq '')) {
    my ($rev) = grep(/\$Revision:\s*[0-9\.]+\s*\$/, @raw);
    return unless defined $rev;
    $rev      =~ s/.*\$Revision:\s*([0-9\.]+)\s*\$[.\r\n]*/$1/;
    return $rev;
  }
  return "$v_maj.$v_min.$v_pat";
}

1;
