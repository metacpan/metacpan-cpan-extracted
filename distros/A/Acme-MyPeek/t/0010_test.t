use strict;
use warnings;

use Test::More tests => 8;

use_ok('Acme::MyPeek');
use Config;

showd('use64bitall');
showd('use64bitint');
showd('usecrosscompile');
showd('uselongdouble');
showd('usemorebits');

my $lv;
my ($d1, $d2, $d3);

my $hi = hi(); $lv = lv(); ($d1, $d2, $d3) = deb_hi();
diag("hi = <$hi>, lv = <$lv>, d1 = <$d1>, d2 = <$d2>, d3 = <$d3>");

my $hd = hd();  $lv = lv(); ($d1, $d2, $d3) = deb_hd();
diag("hd = <$hd>, lv = <$lv>, d1 = <$d1>, d2 = <$d2>, d3 = <$d3>");

is(  $hi,     sprintf('%u', $hi),     'hi() '    .'== sprintf(hi()'.    ')');
isnt($hi + 1, sprintf('%u', $hi + 1), 'hi() + 1 '.'!= sprintf(hi()'.' + 1)');
ok($hi > 100,                         'hi() > 100');
ok($hd > 100,                         'hd() > 100');
is(dt(5),     'IV',                   'dt(5)');
is(dt(1.23),  'NV',                   'dt(1.23)');
is(dt("abc"), 'PV',                   'dt("abc")');

sub showd {
    my ($key) = @_;

    diag(sprintf('Config%-20s = %s', "{'$key'}", (defined($Config{$key}) ? "'$Config{$key}'" : 'undef')));
}
