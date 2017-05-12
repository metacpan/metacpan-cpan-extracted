# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Untaint-telephone.t'

#########################

use Test::More tests => 15;
BEGIN { use_ok('CGI::Untaint::telephone') };

#########################

my $regex = CGI::Untaint::telephone::_untaint_re();
ok( '07987654321' =~ $regex, 'valid number' );
ok( '+447987654321' =~ $regex, 'valid intl number' );
ok( '079-8765-4321' =~ $regex, 'valid number w/dashes' );
ok( '+4479-8765-4321' =~ $regex, 'valid intl number w/dashes' );
ok( '4479 8765 4321' =~ $regex, 'valid number w/spaces' );

ok( '4479*8765/4321' !~ $regex, 'valid number with garbage seperators' );
ok( 'foobar' !~ $regex, 'not a number' );
ok( '123abc456' !~ $regex, 'Still not a number' );
ok( '' !~ $regex, 'empty (should fail)' );
ok( '999999999999999999999999999999999999999999999999999' !~ $regex,
    'way too long' );

use_ok('CGI::Untaint');
my $vars = {
    mobile => '+4479-8765-4321',
    mobile2 => '4479 1234 3214',
    mobile3 => ' '
};
my $untainter = CGI::Untaint->new($vars);
my $mobile = $untainter->extract(-as_telephone => 'mobile');
ok($mobile eq '+447987654321', 'strip dashes');

my $mobile2 = $untainter->extract(-as_telephone => 'mobile2');
ok($mobile2 eq '447912343214', 'strip spaces');

# and what about empty fields?
my $mobile3 = $untainter->extract(-as_telephone => 'mobile3');
is($mobile3, undef, 'empty field');
