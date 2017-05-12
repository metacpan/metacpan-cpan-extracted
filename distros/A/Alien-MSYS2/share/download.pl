use strict;
use warnings;
use Config;
use 5.008001;
use Config;
use HTTP::Tiny;
use Archive::Extract;
use File::Basename qw( dirname );
use File::Spec;
use File::Path qw( rmtree mkpath );
use JSON::PP qw( encode_json );
use Env qw( @PATH );

# list of packages:
# pacman -Qe | awk '{print $1}'

my $arch = $Config{ptrsize} == 8 ? 'x86_64' : 'i686';
my $root = ($ARGV[0]||'') eq '--blib' ? File::Spec->catdir(qw( blib lib auto share dist Alien-MSYS2 )) : File::Spec->rel2abs(dirname( __FILE__ ));

if($^O eq 'msys' && -f "/mingw32_shell.bat")
{
  write_config(
    install_type => 'system',
    msys2_root   => '/',
    probe        => 'msys2 native',
  );
  exit;
}

eval {

  # TRY to find MSYS2 using the user override variable ALIEN_MSYS2_ROOT
  # ways that searching for existing MSYS2 install can fail:
  # 1. ALIEN_FORCE or ALIEN_INSTALL_TYPE specify a share install (see Alien::Base documentation)
  # 2. The ALIEN_MSYS2_ROOT environment variable is not set
  # 3. The MSYS2 environment is not installed at the location specified by ALIEN_MSYS2_ROOT

  die "force" if $ENV{ALIEN_FORCE} || ($ENV{ALIEN_INSTALL_TYPE}||'system') ne 'system';
  die "not defined" unless defined $ENV{ALIEN_MSYS2_ROOT};
  die "not found" unless -f File::Spec->catfile($ENV{ALIEN_MSYS2_ROOT}, 'msys2_shell.cmd');

  write_config(
    install_type => 'system',
    msys2_root   => $ENV{ALIEN_MSYS2_ROOT},
    probe        => 'environment',
  );
  exit;
};

eval {

  # TRY to find MSYS2 using the uninstaller registry
  # ways that searching for existing MSYS2 install can fail:
  # 1. ALIEN_FORCE or ALIEN_INSTALL_TYPE specify a share install (see Alien::Base documentation)
  # 2. No Win32 (ie not MSWin32 or cygwin)
  # 3. Win32API::Registry 0.21 is not installed (it comes with Strawberry, but is not otherwise in core)
  # 4. MSYS2 is not already installed, or wasn't installed with the installer
  
  die "force" if $ENV{ALIEN_FORCE} || ($ENV{ALIEN_INSTALL_TYPE}||'system') ne 'system';

  require Win32API::Registry;
  die "old version" unless Win32API::Registry->VERSION >= 0.21;
  
  my $uninstall_key;
  Win32API::Registry::RegOpenKeyEx(
    Win32API::Registry::HKEY_CURRENT_USER(),
    'software\\microsoft\\windows\\currentversion\\uninstall',
    0,
    Win32API::Registry::KEY_READ(),
    $uninstall_key
  ) || die "unable to get uninstall key";

  my $path;

  my $pos = 0;
  my($sub_key, $class, $time) = ('','','');
  my($name_size, $class_size) = (1024,1024);
  while(Win32API::Registry::RegEnumKeyEx( $uninstall_key, $pos++, $sub_key, $name_size, [], $class, $class_size, $time))
  {
    my $item_key;
    Win32API::Registry::RegOpenKeyEx($uninstall_key, $sub_key, 0, Win32API::Registry::KEY_READ(), $item_key) || next;

    my $display_name;
    if(Win32API::Registry::RegQueryValueEx($item_key, "DisplayName", [], Win32API::Registry::REG_SZ(), $display_name, []))
    {
      if($display_name =~ /^MSYS2 (32|64)bit$/)
      {
        if($1 == ($Config{ptrsize} == 8 ? 64 : 32))
        {
          my $install_location;
          if(Win32API::Registry::RegQueryValueEx($item_key, "InstallLocation", [], Win32API::Registry::REG_SZ(), $install_location, []))
          {
            if(-f File::Spec->catfile($install_location, 'mingw32_shell.bat'))
            {
              $path = $install_location;
            }
          }
        }
      }
    }
    
    Win32API::Registry::RegCloseKey($item_key);

    last if $path;
  }
  
  Win32API::Registry::RegCloseKey($uninstall_key);

  if($path) {
    write_config(
      install_type => 'system',
      msys2_root   => $path,
      probe        => 'uninstaller registry',
    );
    exit;
  }

};

eval {

  # TRY to find MSYS2 using short cuts that are usually installed by the GUI installer
  # ways that searching for existing MSYS2 install can fail:
  # 1. ALIEN_FORCE or ALIEN_INSTALL_TYPE specify a share install (see Alien::Base documentation)
  # 2. No Win32 (ie not MSWin32 or cygwin)
  # 3. Win32::Shortcut is not installed
  # 4. MSYS2 is not already installed, or there are no short cuts for it in the CURRENT user

  die "force" if $ENV{ALIEN_FORCE} || ($ENV{ALIEN_INSTALL_TYPE}||'system') ne 'system';
  
  require Win32;
  require Win32::Shortcut;
  
  my $path = File::Spec->catdir( Win32::GetFolderPath( Win32::CSIDL_PROGRAMS() ), $Config{ptrsize} == 8 ? 'MSYS2 64bit' : 'MSYS2 32bit' );
  die "no $path" unless -d $path;

  $path = find($path);
  
  if($path)
  {
    write_config(
      install_type => 'system',
      msys2_root   => $path,
      probe        => 'shortcut',
    );
    exit;
  }
  
  sub find
  {
    my $path = shift;

    my $short = Win32::Shortcut->new;
    my $dh;
    opendir $dh, $path;
    foreach my $link_name (readdir $dh)
    {
      next if -d $link_name;
      my $link_path = File::Spec->catfile($path, $link_name);
      $short->Load($link_path) || next;
      my $bat = (split /\s+/, $short->{Arguments})[-1];
      next unless -f $bat;
      if($bat =~ /^(.*)[\\\/]mingw32_shell\.bat$/)
      {
        close $dh;
        return $1;
      }
    }

    closedir $dh;
  
    return;
  }
};

unless(defined $ENV{ALIEN_INSTALL_TYPE})
{
  print "You have not requested an install type.  I could not find MSYS2 on your system\n";
  print "By default, Alien::MSYS2 will only download MSYS2 into a share directory if you\n";
  print "request it by setting ALIEN_INSTALL_TYPE to share.\n";
  exit 2;
}

if(($ENV{ALIEN_INSTALL_TYPE}||'share') eq 'system')
{
  print "You requested a system install via the ALIEN_INSTALL_TYPE environment variable\n";
  print "But I was unable to find MSYS2 in on your system.  Please see the Alien::MSYS2\n";
  print "documentation for details.\n";
  exit 2;
}

my $dest = File::Spec->catdir($root, $Config{ptrsize} == 8 ? 'msys64' : 'msys32');

my $filename = "msys2-$arch-latest.tar.xz";

unless(-r $filename)
{
  my $url = "http://repo.msys2.org/distrib/$filename";
  print "Download $url\n";
  my $http_response = HTTP::Tiny->new->get($url);

  die "@{[ $http_response->{status} ]} @{[ $http_response->{reason} ]} on $url"
    unless $http_response->{success};

  my $fh;
  open($fh, '>', "$filename.tmp") 
    || die "unable to open $filename.tmp $!";
  binmode $fh;
  print($fh $http_response->{content}) 
    || die "unable to write to $filename.tmp $!";
  close($fh) 
    || die "unable to close $filename.tmp $!";
  rename("$filename.tmp" => $filename)
    || die "unable to rename $filename.tmp => $filename";
}

unless(-d $dest)
{
  my $ae = Archive::Extract->new( archive => $filename );
  print "Extract  $filename => $root\n";
  $ae->extract( to => $root ) || do{
    rmtree( $dest, 0, 0 );
    die "error extracting: @{[ $ae->error ]}";
  };
  
  if($^O eq 'MSWin32')
  {
    local $ENV{PATH} = $ENV{PATH};
    unshift @PATH, File::Spec->catdir($dest, qw( usr bin ));
    system 'bash', '-l', -c => 'true';
    system 'bash', '-l', -c => 'pacman -Syuu --noconfirm';
    system 'bash', '-l', -c => 'pacman -S make --noconfirm';
  }
  
  write_config(
    install_type => 'share',
    probe        => 'share',
  );
}

sub write_config
{
  my %config = @_;
  $config{msys2_root} =~ s{\\}{/}g if defined $config{msys2_root};
  $config{ptrsize} = $Config{ptrsize};
  mkpath $root, 0, 0755;  
  my $filename = File::Spec->catfile($root, 'alien_msys2.json');
  open my $fh, '>', $filename;
  print $fh encode_json(\%config);
  close $fh;
}
