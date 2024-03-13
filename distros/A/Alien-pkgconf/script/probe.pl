use strict;
use warnings;
use Config;
use File::Spec;
use JSON::PP qw( encode_json decode_json );

my $status_filename = File::Spec->catfile('_alien', '01probe.json');
exit if -e $status_filename;

my $archlib = do {
  my($type, $perl, $site, $vendor) = @ARGV;
  die "invoke from makefile" unless $type && $perl && $site;
  $type eq 'perl' ? $perl : $type eq 'site' ? $site : $type eq 'vendor' ? $vendor : die "illegal INSTALLDIRS ($type)";
};
$archlib =~ s{\\}{/}g if $^O eq 'MSWin32';
my @prefix = ($archlib, qw( auto share dist Alien-pkgconf ));

my %status = (
  prefix => \@prefix
);

#my @pkg_config_dir;
#my @system_libdir;
#my @system_includedir;

# These are based on experience in development of PkgConfig.pm:

$status{system_libdir}     = ['/usr/lib'];
$status{system_includedir} = ['/usr/include'];

sub is_solaris      { !! ($^O eq 'solaris'                                           ) }
sub is_linux_gentoo { !! ($^O eq 'linux' && -f '/etc/gentoo-release'                 ) }
sub is_linux_alpine { !! ($^O eq 'linux' && -f '/etc/alpine-release'                 ) }
sub is_linux_debian { !! ($^O =~ /^(gnukfreebsd|linux)$/ && -r "/etc/debian_version" ) }
sub is_freebsd      { !! ($^O eq 'freebsd' || $^O eq 'dragonfly'                     ) }
sub is_cygwin       { !! ($^O eq 'cygwin'                                            ) }
sub is_windows      { !! ($^O eq 'MSWin32'                                           ) }
sub is_netbsd       { !! ($^O eq 'netbsd'                                            ) }
sub is_openbsd      { !! ($^O eq 'openbsd'                                           ) }
sub is_macos        { !! ($^O eq 'darwin'                                            ) }

sub is_linux_redhat
{
  return 0 unless $^O eq 'linux';
  #return 1 if -r '/etc/redhat-release';
  if(-r '/etc/os-release')
  {
    open my $fh, '<', '/etc/os-release';
    while(my $line = <$fh>) {
      return 1 if $line =~ /(centos|fedora|redhat|amazon linux)/i;
    }
    close $fh;
  }
}

if(is_solaris())
{
  if($Config{ptrsize} == 8)
  {
    $status{pkg_config_dir}    = [qw(
      /usr/local/lib/64/pkgconfig
      /usr/local/share/pkgconfig
      /usr/lib/64/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = [qw(
      /usr/local/lib/64
      /usr/lib/64
    )];
    $status{system_includedir} = [qw(
      /usr/local/include
      /usr/include
    )];
  }
  else
  {
    $status{pkg_config_dir}    = [qw(
      /usr/local/lib/pkgconfig
      /usr/local/share/pkgconfig
      /usr/lib/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = [qw(
      /usr/local/lib
      /usr/lib
    )];
    $status{system_includedir} = [qw(
      /usr/local/include
      /usr/include
    )];
  }
}

elsif(is_linux_gentoo())
{
  if($Config{ptrsize} == 8)
  {
    $status{pkg_config_dir}    = [qw(
      /usr/lib64/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = ['/usr/lib64'];
  }
  else
  {
    $status{pkg_config_dir}    = [qw(
      /usr/lib/pkgconfig
      /usr/share/pkgconfig
    )];
  }
}

elsif(is_linux_alpine())
{
  $status{pkg_config_dir}    = [qw(
    /usr/lib/pkgconfig
    /usr/share/pkgconfig
  )];
  $status{system_libdir}     = [qw(
    /lib
    /usr/lib
  )];
  $status{system_includedir} = [qw(
        /usr/include
  )];

}

elsif(is_linux_debian())
{

  my $arch;
  if(-x "/usr/bin/dpkg-architecture")
  {
    # works if dpkg-dev is installed
    # rt96694
    ($arch) = map { chomp; (split /=/)[1] }
              grep /^DEB_HOST_MULTIARCH=/,
              `/usr/bin/dpkg-architecture`;
  }
  elsif(-x "/usr/bin/gcc")
  {
    # works if gcc is instaled
    $arch = `/usr/bin/gcc -dumpmachine`;
    chomp $arch;
  }
  else
  {
    my $deb_arch = `dpkg --print-architecture`;
    if($deb_arch =~ /^amd64/)
    {
      if($^O eq 'linux') {
        $arch = 'x86_64-linux-gnu';
      } elsif($^O eq 'gnukfreebsd') {
        $arch = 'x86_64-kfreebsd-gnu';
      }
    }
    elsif($deb_arch =~ /^i386/)
    {
      if($^O eq 'linux') {
        $arch = 'i386-linux-gnu';
      } elsif($^O eq 'gnukfreebsd') {
        $arch = 'i386-kfreebsd-gnu';
      }
    }
  }

  if($arch)
  {
    if(scalar grep /--print-foreign-architectures/, `dpkg --help`)
    {
      $status{pkg_config_dir}    = [
        "/usr/local/lib/$arch/pkgconfig",
        "/usr/local/lib/pkgconfig",
        "/usr/local/share/pkgconfig",
        "/usr/lib/$arch/pkgconfig",
        "/usr/lib/pkgconfig",
        "/usr/share/pkgconfig"
      ];
      $status{system_libdir}     = [
        "/usr/lib",
        "/usr/local/lib",
        "/usr/local/lib/$arch",
        "/usr/lib/$arch",
      ];
      $status{system_includedir} = [
        "/usr/include",
        "/usr/local/include",
      ];
    }
    else
    {
      $status{pkg_config_dir}    = [
        "/usr/local/lib/pkgconfig",
        "/usr/local/lib/pkgconfig/$arch",
        "/usr/local/share/pkgconfig",
        "/usr/lib/pkgconfig",
        "/usr/lib/pkgconfig/$arch",
        "/usr/share/pkgconfig"
      ];
      $status{system_libdir}     = [
        "/usr/lib",
        "/usr/local/lib",
      ];
      $status{system_includedir} = [
        "/usr/include",
        "/usr/local/include",
      ];
    }
  }
  else
  {
    $status{pkg_config_dir}    = [
      "/usr/local/lib/pkgconfig",
      "/usr/local/share/pkgconfig",
      "/usr/lib/pkgconfig",
      "/usr/share/pkgconfig"
    ];
    $status{system_libdir}     = [
      "/usr/lib",
      "/usr/local/lib",
    ];
    $status{system_includedir} = [
      "/usr/include",
      "/usr/local/include",
    ];
  }
}

elsif(is_linux_redhat())
{
  if(-d "/usr/lib64/pkgconfig")
  {
    $status{pkg_config_dir}    = [
      '/usr/lib64/pkgconfig',
      '/usr/share/pkgconfig',
    ];
    $status{system_libdir}     = ['/usr/lib64'];
  }
  else
  {
    $status{pkg_config_dir}    = [
      '/usr/lib/pkgconfig',
      '/usr/share/pkgconfig',
    ];
  }
}

elsif(is_freebsd())
{
  $status{pkg_config_dir} = [
    "/usr/local/libdata/pkgconfig",
    "/usr/libdata/pkgconfig",
  ];
}

elsif(is_cygwin())
{
  $status{pkg_config_dir}    = [qw(
    /usr/lib/pkgconfig
    /usr/share/pkgconfig
  )];
}

elsif(is_windows())
{
  if($Config::Config{myuname} =~ /strawberry-perl/)
  {
    my($vol, $dir, $file) = File::Spec->splitpath($^X);
    my @dirs = File::Spec->splitdir($dir);
    splice @dirs, -3;
    my $path = (File::Spec->catdir($vol, @dirs, qw( c lib pkgconfig )));
    $path =~ s{\\}{/}g;
    $status{pkg_config_dir} = [
      $path,
    ];
    $status{system_libdir}     = [
      '/mingw/lib',
      '/mingw/lib/pkgconfig/../../lib',
    ];
    $status{system_includedir} = [
      '/mingw/include',
      '/mingw/lib/pkgconfig/../../include',
    ];
  }
  else
  {
    die "do not know enough please open ticket: https://github.com/PerlAlien/Alien-pkgconf/issues";
  }
}

elsif(is_netbsd())
{
  $status{pkg_config_dir} = [qw(
    /usr/pkg/lib/pkgconfig
    /usr/pkg/share/pkgconfig
    /usr/X11R7/lib/pkgconfig
    /usr/lib/pkgconfig
  )];
}

elsif(is_openbsd())
{
  $status{pkg_config_dir} = [qw(
    /usr/lib/pkgconfig
    /usr/local/lib/pkgconfig
    /usr/local/share/pkgconfig
    /usr/X11R6/lib/pkgconfig
    /usr/X11R6/share/pkgconfig
  )];
}

elsif(is_macos())
{
  $status{pkg_config_dir} = [qw(
    /usr/lib/pkgconfig
    /usr/local/lib/pkgconfig
  )];
}

else
{
  die "do not know enough about this OS to probe for correct paths.  Please open a ticket https://github.com/PerlAlien/Alien-pkgconf/issues";
}

my $my_pkg_config_dir = File::Spec->catdir(@prefix, 'lib', 'pkgconfig');
$my_pkg_config_dir =~ s{\\}{/}g if $^O eq 'MSWin32';
unshift @{ $status{pkg_config_dir} }, $my_pkg_config_dir;

mkdir '_alien' unless -d '_alien';
open my $fh, '>', $status_filename;
print $fh JSON::PP->new->utf8->canonical->encode(\%status);
close $fh;
