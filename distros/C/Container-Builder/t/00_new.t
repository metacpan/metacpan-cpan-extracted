use strict;
use Test::More;
use Container::Builder;

my $b = Container::Builder->new(debian_pkg_hostname => 'iaan.be');
ok($b, 'We can make a Container::Builder instance');

done_testing;
