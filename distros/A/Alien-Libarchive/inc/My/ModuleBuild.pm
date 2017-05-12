package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use Config;
use Alien::Libarchive::Installer;
use Alien::bz2::Installer;
use Alien::LZO::Installer;
use File::Spec;
use FindBin ();

my $type = eval { require FFI::Raw } ? 'both' : 'compile';

# Note: for historical / hysterical reasons, the install type is one of:
# 1. system, use the system libarchive
# 2. share, build your own libarchive, both static and shared
#    the static version will be used for XS modules and the shared one
#    will be used for FFI modules.

sub _list ($)
{
  ref($_[0]) eq 'ARRAY' ? $_[0] : [$_[0]];
}

sub _catfile {
  my $path = File::Spec->catfile(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}

sub _catdir {
  my $path = File::Spec->catdir(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}

sub new
{
  my($class, %args) = @_;

  my $system;

  $ENV{ALIEN_LIBARCHIVE} = 'share' if $ENV{ALIEN_FORCE} && ! defined $ENV{ALIEN_LIBARCHIVE};

  unless(($ENV{ALIEN_LIBARCHIVE} || 'system') eq 'share')
  {
    $system = eval {
      Alien::Libarchive::Installer->system_install(
        type  => $type,
        alien => 0,
      )
    };
  }

  unless(defined $system)
  {
    foreach my $class (map { "Alien::$_\::Installer" } qw( Libarchive bz2 LZO ))
    {
      my $prereqs = $class->build_requires;  
      while(my($mod,$ver) = each %$prereqs)
      {
        $args{build_requires}->{$mod} = $ver;
      }
    }
  }

  my $self = $class->SUPER::new(%args);

  $self->config_data( name => 'libarchive' );
  $self->config_data( already_built => 0 );
  $self->config_data( msvc => $^O eq 'MSWin32' && $Config{cc} =~ /cl(\.exe)?$/i ? 1 : 0 );
  
  $self->add_to_cleanup( '_alien', '_alien_libarchive', '_alien_bz2', '_alien_lzo', 'share/libarchive019' );
  
  if(defined $system)
  {
    print "Found libarchive " . $system->version . " from system\n";
    print "You can set ALIEN_LIBARCHIVE=share to force building from source\n";
    $self->config_data( install_type => 'system' );
    $self->config_data( cflags       => _list $system->cflags );
    $self->config_data( libs         => _list $system->libs );
    $self->config_data( version      => $system->version );
  }
  else
  {
    print "Did not find working libarchive, will download and install from the Internet\n";
    $self->config_data( install_type => 'share' );
  }
  
  $self;
}

sub ACTION_build
{
  my $self = shift;
  
  if($self->config_data('install_type') eq 'share')
  {
    unless($self->config_data('already_built'))
    {
      my $prefix = _catdir($FindBin::Bin, 'share', 'libarchive019' );

      local $ENV{CONFIG_SITE} = _catfile($FindBin::Bin, '_alien', 'config.site');
      do {
        my $lib = _catdir($prefix, 'lib');
        my $inc = _catdir($prefix, 'include');
        my $dll = _catdir($prefix, 'dll');
      
        mkdir(_catdir($FindBin::Bin, '_alien'));
        open my $fh, '>', $ENV{CONFIG_SITE};
        print $fh "#!/bin/sh\n",
                  "if [ -n \"\$CPPFLAGS\" ] ; then\n",
                  "  CPPFLAGS=\"\$CPPFLAGS -I$inc\"\n",
                  "else\n",
                  "  CPPFLAGS=\"-I$inc\"\n",
                  "fi;\n",
                  "if [ -n \"\$LDFLAGS\" ] ; then\n",
                  "  LDFLAGS=\"\$LDFLAGS -L$lib -L$dll\"\n",
                  "else\n",
                  "  LDFLAGS=\"-L$lib -L$dll\"\n",
                  "fi;\n";
        close $fh;
      };

      if(eval { require Alien::LZO::Installer; })
      {
        my $build = eval { Alien::LZO::Installer->system_install };
        unless($build)
        {
          my $build_dir = _catdir($FindBin::Bin, '_alien_lzo');
          mkdir $build_dir unless -d $build_dir;
          $build = eval { Alien::LZO::Installer->build_install($prefix, dir => $build_dir) };
        }
      }

      if(eval { require Alien::bz2::Installer; })
      {
        my $build = eval { Alien::bz2::Installer->system_install };
        unless($build)
        {
          my $build_dir = _catdir($FindBin::Bin, '_alien_bz2');
          mkdir $build_dir unless -d $build_dir;
          $build = eval { Alien::bz2::Installer->build_install($prefix, dir => $build_dir) };

          if(defined $build)
          {
            if($^O eq 'MSWin32')
            {
              my $dir = _catdir($prefix, 'dll');
              mkdir $dir;
              my $la = _catfile($dir, 'libbz2.la');
              open my $fh, '>', $la;
              binmode $fh;
              print $fh _bz2_la_file($prefix);
              close $fh;
            }
          }
        }
        
      }
    
      my $build_dir = _catdir($FindBin::Bin, '_alien_libarchive');
      mkdir $build_dir unless -d $build_dir;
      mkdir $prefix unless -d $prefix;
      my $build = Alien::Libarchive::Installer->build_install( $prefix, dir => $build_dir );
      $self->config_data( cflags => [grep !/^-I/, @{ _list $build->cflags }] );
      $self->config_data( libs =>   [grep !/^-L/, @{ _list $build->libs }] );
      if($self->config_data('msvc'))
      {
        $self->config_data( libs =>   [grep !/^(\/|-)libpath/i, @{ _list $build->libs }] );
      }
      $self->config_data( version => $build->version );

      printf "cflags: %s\n", join ' ', @{ $self->config_data('cflags') };
      printf "libs:   %s\n", join ' ', @{ $self->config_data('libs') };
      printf "msvc:   %d\n", $self->config_data('msvc');
      
      do {
        opendir my $dh, _catdir($prefix, 'dll');
        my @list = grep { ! -l _catfile($prefix, 'dll', $_) }
                   grep { /\.so/ || /\.(dll|dylib)$/ }
                   grep !/^(libbz2|bzip2.dll|liblzo2)/,
                   grep !/^\./,
                   sort
                   readdir $dh;
        closedir $dh;
        print "dlls:\n";
        print "  - $_\n" for @list;
        $self->config_data( dlls => \@list );
      };
      
      $self->config_data( already_built => 1 );
    }
  }
  
  $self->SUPER::ACTION_build(@_);

  my $module = $self->module_name;
  my @parts = split /::/, $module;
  my $arch_dir = File::Spec->catdir($self->blib, 'arch', 'auto', @parts);
  File::Path::mkpath($arch_dir, 0, oct(777)) unless -d $arch_dir;
  open my $fh, '>', File::Spec->catfile($arch_dir, $parts[-1].".txt");
  close $fh;
}

my $bz2_la_template;
sub _bz2_la_file
{
  my($prefix) = @_;
  unless(defined $bz2_la_template)
  {
    $bz2_la_template = do { local $/; <DATA> };
  }
  my $bz2_la = $bz2_la_template;
  $bz2_la =~ s{##PREFIX##}{$prefix}g;
  $bz2_la;
}

1;

__DATA__
# libbz2.la - a libtool library file
# Generated by libtool (GNU libtool) 2.4.2 Debian-2.4.2-1.1
#
# Please DO NOT delete this file!
# It is necessary for linking the library.

# The name that we can dlopen(3).
dlname='../bin/bzip2.dll'

# Names of this library.
library_names='../dll/libbz2.dll.a'

# The name of the static archive.
old_library='libbz2.a'

# Linker flags that can not go in dependency_libs.
inherited_linker_flags=''

# Libraries that this one depends upon.
dependency_libs=''

# Names of additional weak libraries provided by this library
weak_library_names=''

# Version information for libbz2.
current=14
age=1
revision=2

# Is this an already installed library?
installed=yes

# Should we warn about portability when linking against -modules?
shouldnotlink=no

# Files to dlopen/dlpreopen
dlopen=''
dlpreopen=''

# Directory that this library needs to be installed in:
libdir='##PREFIX##/lib'
