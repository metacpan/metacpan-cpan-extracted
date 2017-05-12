package Alien::UnRTF::ModuleBuild;
 
use parent 'Alien::Base::ModuleBuild';
use IPC::Open3;

sub alien_name {
  'unrtf';
}
 
sub alien_check_installed_version {
  if (`which unrtf`) {
    my $pid = open3(\*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, "unrtf", "--version");
    my $version = <CHLD_ERR>;
    return $version;
  }
  else {
    return undef;
  }
}

sub alien_bin_requires {
  {
    'Alien::Autotools' => 0,
  }
}

sub alien_build_commands {
  [ 'sh bootstrap', '%c --prefix=%s', 'make' ];
}

sub alien_repository {
  {
    protocol => 'http',
    host     => 'ftp.gnu.org',
    location => '/gnu/unrtf',
    pattern  => qr/^unrtf[_-]([\d\.-]+)\.tar\.gz$/,
  };
}

1;
