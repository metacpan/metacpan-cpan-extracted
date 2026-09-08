use v5.40;
use blib;
use Test2::V0;
use Alien::lsquic;
#
my $lsquic = Alien::lsquic->new;
isa_ok $lsquic, ['Alien::lsquic'],         'isa Alien::lsquic';
isa_ok $lsquic, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $lsquic->package_names ], ['lsquic'], 'package_names is lsquic';
#
done_testing;
