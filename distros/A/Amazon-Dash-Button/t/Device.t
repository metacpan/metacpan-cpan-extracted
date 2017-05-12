use strict;
use warnings;

use Test::More tests => 14;
use Test::Deep;
use FindBin;

use lib $FindBin::Bin. '/../lib';

use_ok q{Amazon::Dash::Button::Device};

my $adb;

ok !eval { Amazon::Dash::Button::Device->new(); 1 }, 'new fail';
like $@, qr{mac address is undefined};

ok eval { Amazon::Dash::Button::Device->new( mac => q{00:11:22:33:44:55}); 1 }, 'new succeeds without onClick';

$adb = Amazon::Dash::Button::Device->new( mac => q{00:11:22:33:44:55}, onClick => sub { note "boom" });
isa_ok $adb, 'Amazon::Dash::Button::Device';

ok $adb->_fork_for_onClick;

my $click = 0;

$adb = Amazon::Dash::Button::Device->new( mac => q{00:11:22:33:44:55}, onClick => sub { ++$click; note "this is a click" }, _fork_for_onClick => 0);
isa_ok $adb, 'Amazon::Dash::Button::Device';

no warnings qw{redefine once};
*Amazon::Dash::Button::Device::debug = sub { note @_ };

ok !$adb->_fork_for_onClick;

ok !$adb->check();
ok !$adb->check('foo');
ok !$adb->check('00:11:22:33:44:66');

ok $adb->check('00:11:22:33:44:55'), 'click';
is $click, 1;
ok !$adb->check('00:11:22:33:44:55'), 'do not click twice in the timeout window';