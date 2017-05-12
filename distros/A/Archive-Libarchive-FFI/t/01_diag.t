use strict;
use warnings;
use lib 'inc/Linux-Distribution/lib';
use Config;
use Test::More tests => 1;

pass 'okay';

diag '';
diag '';
diag '';
diag 'os                   = ', $Config{osname};
diag 'version              = ', $Config{osvers};

if($^O eq 'linux')
{
  require Linux::Distribution;
  my $linux = Linux::Distribution->new;
  diag "distribution_name    = ", $linux->distribution_name;
  diag "distribution_version = ", $linux->distribution_version;
}

diag '';
diag '';
diag '';
