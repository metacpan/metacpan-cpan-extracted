use v5.40;
use blib;
use Test2::V0;
use Alien::Zlib;
#
ok my $zlib = Alien::Zlib->new, 'Alien::Zlib->new';
#
isa_ok $zlib, ['Alien::Zlib'];
isa_ok $zlib, ['Alien::Base'];
#
is $zlib->install_type, D(), 'install_type resolves';
diag $zlib->install_type;
#
done_testing;
