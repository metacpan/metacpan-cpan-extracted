use Acme::Elk;
use Test::More tests => 4;

# TODO More tests!

can_ok(__PACKAGE__, 'has');
can_ok(__PACKAGE__, 'around');
can_ok(__PACKAGE__, 'before');
can_ok(__PACKAGE__, 'after');

1;
