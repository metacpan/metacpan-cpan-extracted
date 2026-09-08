use v5.40;
use blib;
use Test2::V0;
use Alien::Ninja;
#
my $ninja = Alien::Ninja->new;
isa_ok $ninja, ['Alien::Ninja'];
isa_ok $ninja, ['Alien::Base'];
ok defined( $ninja->install_type // () ), 'install_type resolves';
#
done_testing;
