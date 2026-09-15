use v5.40;
use blib;
use Test2::V0;
use Exotic::Raylib6;
#
my $raylib = Exotic::Raylib6->new;
isa_ok $raylib, ['Exotic::Raylib6'],       'isa Exotic::Raylib6';
isa_ok $raylib, ['Alien::Xrepo::Runtime'], 'isa Alien::Xrepo::Runtime';
is [ $raylib->package_names ], ['raylib'], 'package_names is raylib';
#
done_testing;
