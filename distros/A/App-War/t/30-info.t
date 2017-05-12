use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use Test::Warn;

use_ok('App::War');
my $war = App::War->new;

# turn warnings on
$war->{verbose} = 1;
warning_like { $war->_info("Little Bo Peep") } qr/Little/;

# and turn warnings off
$war->{verbose} = 0;
warning_is { $war->_info("has lost her sheep") } [], 'no warning';

