package My::Utility;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(check_config_script check_prebuilt_binaries check_prereqs_libs check_prereqs_tools find_SDL_dir find_file check_header
                    sed_inplace get_dlext $inc_lib_candidates $source_packs check_perl_buildlibs);
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
$inc_lib_candidates->{$ENV{SDL_INC}}            = $ENV{SDL_LIB}               if exists $ENV{SDL_LIB} && exists $ENV{SDL_INC};

#### packs with prebuilt binaries
# - all regexps has to match: arch_re ~ $Config{archname}, cc_re ~ $Config{cc}, os_re ~ $^O
# - the order matters, we offer binaries to user in the same order (1st = preffered)
my $prebuilt_binaries = [
    {
      title    => "Binaries Win/32bit SDL-1.2.14 (extended, 20100704) RECOMMENDED\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf, sound, svg, rtf, Pango)",
      url      => [
        'http://strawberryperl.com/package/kmx/sdl/Win32_SDL-1.2.14-extended-bin_20100704.zip',
        'http://froggs.de/libsdl/Win32_SDL-1.2.14-extended-bin_20100704.zip',
      ],
      sha1sum  => '98409ddeb649024a9cc1ab8ccb2ca7e8fe804fd8',
      arch_re  => qr/^MSWin32-x86-multi-thread(-64int)?$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
    {
      title    => "Binaries Win/32bit SDL-1.2.14 (extended, 20111205)\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf, sound, svg, rtf, Pango)",
      url      => [
        'http://strawberryperl.com/package/kmx/sdl/Win32_SDL-1.2.14-extended-bin_20111205.zip',
        'http://froggs.de/libsdl/Win32_SDL-1.2.14-extended-bin_20111205.zip',
      ],
      sha1sum  => '553b7e21bb650d047ec9f2a5f650c67d76430e61',
      arch_re  => qr/^MSWin32-x86-multi-thread(-64int)?$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
    {
      title    => "Binaries Win/64bit SDL-1.2.14 (extended, 20100824)\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf, sound, svg, rtf, Pango)\n" .
                  "\tBEWARE: binaries are using old ABI - will fail with the latest gcc\n" .
                  "\tBEWARE: this is intended just for old strawberryperl 5.12.x/64bit",
      url      => [
        'http://strawberryperl.com/package/kmx/sdl/Win64_SDL-1.2.14-extended-bin_20100824.zip',
        'http://froggs.de/libsdl/Win64_SDL-1.2.14-extended-bin_20100824.zip',
      ],
      sha1sum  => 'ccffb7218bcb17544ab00c8a1ae383422fe9586d',
      arch_re  => qr/^MSWin32-x64-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
      gccversion_re => qr/^4\.4\.3$/, #specific to the old gcc compiler used in 64bit strawberryperl 5.12.x
    },
    {
      title    => "Binaries Win/64bit SDL-1.2.14 (extended, 20111205) RECOMMENDED\n" .
                  "\t(gfx, image, mixer, net, smpeg, ttf, sound, svg, rtf, Pango)",
      url      => [
        'http://strawberryperl.com/package/kmx/sdl/Win64_SDL-1.2.14-extended-bin_20111205.zip',
        'http://froggs.de/libsdl/Win64_SDL-1.2.14-extended-bin_20111205.zip',
      ],
      sha1sum  => '35f3b496ca443a9d14eff77e9e26acfa813afafd',
      arch_re  => qr/^MSWin32-x64-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
      gccversion_re => qr/^4\.(4\.[5-9]|[5-9]\.[0-9])$/,
    },
    {
      title    => "Binaries Win/32bit SDL-1.2.15 (20120612)\n" .
                  "\t(gfx, image, mixer, smpeg, ttf)",
      url      => [
        'http://froggs.de/libsdl/Win32_SDL-1.2.15-20120612.zip',
      ],
      sha1sum  => '22c531c1d0cc5a363c05045760870b2f45e9d0da',
      arch_re  => qr/^MSWin32/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/cl/,
    },
 ];

#### tarballs with source codes
our $source_packs = [
  {
    title   => "Source code build\n    ",
    members => [
      {
        pack => 'z',
        version => '1.2.5',
        dirname => 'zlib-1.2.5',
        url => [
          'http://froggs.de/libz/zlib-1.2.5.tar.gz',
        ],
        sha1sum  => '8e8b93fa5eb80df1afe5422309dca42964562d7e',
        patches => [
          'zlib-1.2.5-bsd-ldconfig.patch',
        ],
        prereqs => {
          libs => [ ]
        }
      },
      {
        pack => 'jpeg',
        version => '8b',
        dirname => 'jpeg-8b',
        url => [
          'http://www.ijg.org/files/jpegsrc.v8b.tar.gz',
          'http://froggs.de/libjpeg/jpegsrc.v8b.tar.gz',
        ],
        sha1sum  => '15dc1939ea1a5b9d09baea11cceb13ca59e4f9df',
        patches => [
          'jpeg-8a_cygwin.patch',
        ],
        prereqs => {
          libs => [ ]
        }
      },
      {
        pack => 'tiff',
        version => '3.9.1',
        dirname => 'tiff-3.9.1',
        url => [
          'http://froggs.de/libtiff/tiff-3.9.1.tar.gz',
          'ftp://ftp.remotesensing.org/pub/libtiff/tiff-3.9.1.tar.gz',
        ],
        sha1sum  => '675ad1977023a89201b80cd5cd4abadea7ba0897',
        patches => [ ],
        prereqs => {
          libs => [ ]
        }
      },
      {
        pack => 'png',
        version => '1.4.1',
        dirname => 'libpng-1.4.1',
        url => [
          'http://froggs.de/libpng/libpng-1.4.1.tar.gz',
        ],
        sha1sum  => '7a3488f5844068d67074f2507dd8a7ed9c69ff04',
        prereqs => {
          libs => [
            'z',
          ]
        }
      },
      {
        pack => 'freetype',
        version => '2.3.12',
        dirname => 'freetype-2.3.12',
        url => [
          'http://mirror.lihnidos.org/GNU/savannah/freetype/freetype-2.3.12.tar.gz',
          'http://froggs.de/libfreetype/freetype-2.3.12.tar.gz',
        ],
        sha1sum  => '0082ec5e99fec5a1c6d89b321a7e2f201542e4b3',
        prereqs => {
          libs => [ ]
        }
      },
      {
        pack => 'SDL',
        version => '1.2.15',
        dirname => 'SDL-1.2',
        url => [
          'http://froggs.de/libsdl/SDL-1.2-2b923729fd01.tar.gz',
        ],
        sha1sum  => 'ec9841377403e8d1bcfd76626434be64d11f59f0',
        patches => [
          'test1.patch',
          'SDL-1.2-openbsd-rldflags.patch',
          'libsdl-1.2.15-const-xdata32.1.patch',
          'libsdl-1.2.15-const-xdata32.2.patch',
          'libsdl-1.2.15-const-xdata32.3.patch',
          'libsdl-1.2.15-const-xdata32.4.patch',
          'SDL-1.2.15-PIC-in-CFLAGS.patch',
          'SDL-1.2.15-Makefile.in-OBJECTS.patch',
          'SDL-1.2.15-mavericks-cgdirectpallete.patch',
        ],
        prereqs => {
          libs => [
            'pthread',
          ]
        },
      },
      {
        pack => 'SDL_image',
        version => '1.2.11',
        dirname => 'SDL_image-1.2.11',
        url => [
          'http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.11.tar.gz',
          'http://froggs.de/libsdl/SDL_image-1.2.11.tar.gz',
        ],
        sha1sum  => 'dd384ff87848595fcc0691833431ec5029f973c7',
        patches => [
          'SDL_image-1.2.11-CGFloat.patch',
          'SDL_image-1.2.11-libpng-flags.patch',
        ],
        prereqs => {
          libs => [
            'jpeg', 'tiff', 'png',
          ]
        }
      },
      {
        pack => 'ogg',
        version => '1.3.0',
        dirname => 'libogg-1.3.0',
        url => [
          'http://downloads.xiph.org/releases/ogg/libogg-1.3.0.tar.gz',
          'http://froggs.de/libsdl/libogg-1.3.0.tar.gz',
        ],
        sha1sum  => 'a900af21b6d7db1c7aa74eb0c39589ed9db991b8',
        patches => [ ],
      },
      {
        pack => 'vorbis',
        version => '1.3.3',
        dirname => 'libvorbis-1.3.3',
        url => [
          'http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz',
          'http://froggs.de/libsdl/libvorbis-1.3.3.tar.gz',
        ],
        sha1sum  => '8dae60349292ed76db0e490dc5ee51088a84518b',
        patches => [
          'libvorbis-1.3.3-configure.patch',
        ],
        prereqs => {
          libs => [ ]
        }
      },
      {
        pack => 'SDL_mixer',
        version => '1.2.12',
        dirname => 'SDL_mixer-1.2.12',
        url => [
          'http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12.tar.gz',
          'http://froggs.de/libsdl/SDL_mixer-1.2.12.tar.gz',
        ],
        sha1sum  => 'a20fa96470ad9e1052f1957b77ffa68fb090b384',
        patches => [
          'SDL_mixer-1.2.12-native-midi-win32.patch',
        ],
        prereqs => {
          libs => [
            'ogg', 'vorbis',
          ]
        },
      },
      {
        pack => 'SDL_ttf',
        version => '2.0.11',
        dirname => 'SDL_ttf-2.0.11',
        url => [
          'http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.11.tar.gz',
          'http://froggs.de/libsdl/SDL_ttf-2.0.11.tar.gz',
        ],
        sha1sum  => '0ccf7c70e26b7801d83f4847766e09f09db15cc6',
        patches => [ ],
        prereqs => {
          libs => [
            'freetype', # SDL_ttf
          ]
        },
      },
      {
        pack => 'SDL_gfx',
        version => '2.0.25',
        dirname => 'SDL_gfx-2.0.25',
        url => [
          'http://froggs.de/libsdl/SDL_gfx-2.0.25.tar.gz',
          'http://www.ferzkopp.net/Software/SDL_gfx-2.0/SDL_gfx-2.0.25.tar.gz',
        ],
        sha1sum  => '20a89d0b71b7b790b830c70f17ed2c44100bc0f4',
        patches => [ ],
        prereqs => {
          libs => [ ]
        }
      },
      {
        pack => 'SDL_Pango',
        version => '1.2',
        dirname => 'SDL_Pango-0.1.2',
        url => [
          'http://downloads.sourceforge.net/sdlpango/SDL_Pango-0.1.2.tar.gz',
          'http://froggs.de/libsdl/SDL_Pango-0.1.2.tar.gz',
        ],
        sha1sum  => 'c30f2941d476d9362850a150d29cb4a93730af68',
        patches => [
          'SDL_Pango-0.1.2-API-adds.1.patch',
          'SDL_Pango-0.1.2-API-adds.2.patch',
          'SDL_Pango-0.1.2-config-tools.1.patch',
          'SDL_Pango-0.1.2-config-tools.2.patch',
          'SDL_Pango-0.1.2-config-tools.3.patch',
          'SDL_Pango-0.1.2-include-ft2build.h.patch',
        ],
        prereqs => {
          libs => [
            'pangoft2', 'pango', 'gobject', 'gmodule', 'glib', 'fontconfig', 'freetype', 'expat', # SDL_Pango
          ]
        }
      },
    ],
  },
];

sub check_config_script {
  my $script = shift || 'sdl-config';
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
  print "yes, $script\n";
  #returning HASHREF
  return {
    title     => "Already installed SDL ver=$version path=$prefix",
    buildtype => 'use_config_script',
    script    => $script,
    prefix    => $prefix,
  };
}

sub check_prebuilt_binaries
{
  print "checking for prebuilt binaries... ";
#  print "(os=$^O cc=$cc archname=$Config{archname})\n";
  my @good = ();
  foreach my $b (@{$prebuilt_binaries}) {
    if ( ($^O =~ $b->{os_re}) &&
         ($Config{archname} =~ $b->{arch_re}) &&
         ($cc =~ $b->{cc_re}) &&
         (!defined $b->{gccversion_re} || $Config{gccversion} =~ $b->{gccversion_re})
        ) {
      $b->{buildtype} = 'use_prebuilt_binaries';
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
      'SDL_gfx' => 'SDL_gfxPrimitives',
      'SDL'     => 'SDL_version',
    };
    my $header             = (defined $header_map->{$lib}) ? $header_map->{$lib} : $lib;

    my $dlext = get_dlext();
    foreach (keys %$inc_lib_candidates) {
      my $ld = $inc_lib_candidates->{$_};
      next unless -d $_ && -d $ld;
      ($found_dll) = find_file($ld, qr/[\/\\]lib\Q$lib\E[\-\d\.]*\.($dlext[\d\.]*|so|dll)$/);
      $found_dll   = $1 if $found_dll && $found_dll =~/^(.+($dlext|so|dll))/ && -e $1;
      ($found_lib) = find_file($ld, qr/[\/\\]lib\Q$lib\E[\-\d\.]*\.($dlext[\d\.]*|a|dll.a)$/);
      ($found_inc) = find_file($_,  qr/[\/\\]\Q$header\E[\-\d\.]*\.h$/);
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

    if( scalar(@libs) == 1 ) {
      return $ret
        ? [(get_header_version($found_inc) || 'found'), $found_dll]
        : [0, undef];
    }
  }

  return $ret;
}

sub check_perl_buildlibs {
  my @libs    = @_;
  my $ret     = 1;
  my $dlext   = get_dlext();
  my $devnull = File::Spec->devnull();
  for my $lib (@libs) {
    print "checking if perl is linked against $lib... ";
    if($Config{libs}        =~ /\Q-l$lib\E\b/
    || $Config{perllibs}    =~ /\Q-l$lib\E\b/
    || `ldd $^X 2>$devnull` =~ /[\/\\]lib\Q$lib\E[\-\d\.]*\.($dlext[\d\.]*|so|dll)$/) {
      print "yes\n";
      $ret &= 1;
    }
    else {
      print "no\n";
      $ret = 0;
    }
  }
  return $ret;
}

sub check_prereqs {
  my $bp  = shift;
  my $ret = 1;
  $ret   &= check_prereqs_libs(@{$bp->{prereqs}->{libs}}) if defined $bp->{prereqs}->{libs};

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

sub find_SDL_dir {
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
  shift(@pp) if(defined($pp[0]) && $pp[0] eq 'SDL');
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
  my ($fs, $src) = File::Temp::tempfile('aaXXXX', SUFFIX => '.c', UNLINK => 1);
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
    return $Config{so};
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
