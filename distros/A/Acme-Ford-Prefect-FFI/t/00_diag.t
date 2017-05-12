use strict;
use warnings;
use Test::More tests => 1;
use Acme::Alien::DontPanic;
use File::chdir;


diag '';
diag '';
diag '';

if(Acme::Alien::DontPanic->install_type eq 'share')
{
  my $dir = Acme::Alien::DontPanic->dist_dir;
  diag "dir = $dir";
  $CWD = $dir;
  diag `ls -laR`;

  diag '';
  diag '';
}

diag "Acme::Alien::DontPanic->dynamic_libs = ", Acme::Alien::DontPanic->dynamic_libs;

diag '';
diag '';


pass 'and so it goes';
