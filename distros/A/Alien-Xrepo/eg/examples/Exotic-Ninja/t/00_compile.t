use v5.40;
use blib;
use Test2::V0;
use Exotic::Ninja;
#
my $ninja = Exotic::Ninja->new;
isa_ok $ninja, ['Exotic::Ninja'],         'isa Exotic::Ninja';
isa_ok $ninja, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $ninja->package_names ], ['ninja'], 'package_names is ninja';
#
done_testing;
