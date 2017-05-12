use lib 't/lib';
use strict;
use Test;
BEGIN { plan tests => 1 }

use FilterTest;
use Apache::Clickable;

my $out = filters('t/sample.html', 'Apache::Clickable', {
    ClickableTarget => undef,
    ClickableEmail => 'Off',
});
ok($out !~ qr(<a href="mailto:foobar\@foobar\.com">));

