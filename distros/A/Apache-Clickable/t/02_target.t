use lib 't/lib';
use strict;
use Test;
BEGIN { plan tests => 1 }

use FilterTest;
use Apache::Clickable;

my $out = filters('t/sample.html', 'Apache::Clickable', {
    ClickableTarget => '_blank',
    ClickableEmail => 'On',
});
ok($out, qr(<a href="http://www\.foobar\.com/foobar\.html" target="_blank">));


