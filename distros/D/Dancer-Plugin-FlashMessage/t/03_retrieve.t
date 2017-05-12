use Test::More tests => 4, import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;

use_ok 'Dancer::Plugin::FlashMessage';

is(flash(foo => 'bar'), 'bar');
is(flash('foo'), 'bar');
is(flash('foo'), undef);
