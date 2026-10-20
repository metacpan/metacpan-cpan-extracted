use v5.40;
use blib;
use Test2::V0;
use Exotic::Lsquic;
#
my $lsquic = Exotic::Lsquic->new;
isa_ok $lsquic, ['Exotic::Lsquic'],        'isa Exotic::Lsquic';
isa_ok $lsquic, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $lsquic->package_names ], ['lsquic'], 'package_names is lsquic';
#
done_testing;
