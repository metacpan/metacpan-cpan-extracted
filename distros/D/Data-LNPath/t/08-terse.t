use Test::More;

BEGIN {
    eval {
        require Terse;
        Terse->new();
        1;
    } or do {
        plan skip_all => "Terse is not available";
    };
}

use Data::LNPath qw/lnpath/;
my $t = Terse->new;
$t->graft('data', '{"testing": 123}');
my $test = lnpath($t->data, 'testing');
is($test, 123);
done_testing();
