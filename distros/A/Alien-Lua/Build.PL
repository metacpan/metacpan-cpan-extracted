use strict;
use warnings;

my %lua_platforms = map {$_ => 1} qw(
  aix ansi bsd freebsd generic linux macosx mingw posix solaris
);

use Config qw(%Config);
use Getopt::Long qw(GetOptions);
GetOptions(
  'os=s' => \(my $lua_platform)
);
if ($lua_platform and not exists $lua_platforms{$lua_platform}) {
  die "Invalid Lua platform specified on command line: '$lua_platform'. "
      . "Valid platforms are @{[keys %lua_platforms]}";
}

# FIXME any improvements to the platform detection welcome!
# FIXME Proper win32 won't work like this at all. Help (with patches) welcome.
my $os = $Config{osname};
if (not $lua_platform) {
  if ($os =~ /^(?:linux|aix|freebsd|solaris)$/i) {
    $lua_platform = $os;
  }
  elsif ($os =~ /darwin/i) {
    $lua_platform = 'macosx';
  }
  elsif ($os =~ /cygwin/i) {
    $lua_platform = 'mingw';
  }
  elsif ($os =~ /(?:bsd|dragonfly)/i) {
    $lua_platform = 'bsd';
  }
  else {
    $lua_platform = 'generic';
  }
}

use Alien::Base::ModuleBuild;
my $builder = Alien::Base::ModuleBuild->new(
  module_name => 'Alien::Lua',
  license => 'perl',
  configure_requires => {
    'Alien::Base' => '0.003',
    'Module::Build' => 0.38,
    'Config' => '0',
    'Getopt::Long' => '0',
  },
  requires => {
    'perl' => '5.14.0',
    'parent' => '0',
    'Alien::Base' => 0,
  },
  dist_author => 'Steffen Mueller <smueller@cpan.org>',
  alien_name => 'lua',
  alien_repository => {
    protocol => 'local',
    location => 'inc',
    pattern  => qr/^lua-(\d[\d\.]*)\.tar\.gz$/,
  },
  alien_build_commands => [
    q#%x -I../../inc -MLuaMunger -e from_to ../../inc/luaconf.h src/luaconf.h#,
    q#%x -MExtUtils::Command -e cp ../../inc/Makefile_src src/Makefile#,
    qq#make $lua_platform INSTALL_TOP="%s" MYCFLAGS="-fPIC" MYLDFLAGS="-fPIC -shared"#,
    qq#%x -MExtUtils::Command -e mkpath lib#, # wrestle Alien::Base to recognize shared libraries exist
  ],
  alien_install_commands => [
    q#make install INSTALL_TOP="%s" MYCFLAGS="-fPIC" MYLDFLAGS="-fPIC -shared"#
  ],
);

$builder->create_build_script;
