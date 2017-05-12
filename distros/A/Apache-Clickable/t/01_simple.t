use lib 't/lib';
use strict;
use Test;
BEGIN { plan tests => 2 }

use FilterTest;
use Apache::Clickable;

my $out = filters('t/sample.html', 'Apache::Clickable', {
    ClickableTarget => undef,
    ClickableEmail => 'On',
});
ok($out, qr(<a href="http://www\.foobar\.com/foobar\.html">));
ok($out, qr(<a href="mailto:foobar\@foobar\.com">));

