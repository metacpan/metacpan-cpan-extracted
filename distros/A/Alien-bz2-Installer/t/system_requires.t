use strict;
use warnings;
use Test::More tests => 1;
use Alien::bz2::Installer;

my $r = Alien::bz2::Installer->system_requires;

is ref($r), 'HASH', 'system_requires';

if(ref($r) eq 'HASH')
{
  foreach my $key (sort keys %$r)
  {
    note sprintf("%s=%s", $key, $r->{$key});
  }
}
