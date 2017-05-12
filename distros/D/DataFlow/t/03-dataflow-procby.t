use Test::More tests => 10;

use DataFlow;

my $f = DataFlow->new(
    [ sub { uc }, sub { scalar reverse }, sub { lc }, sub { scalar reverse }, ]
);
ok($f);

is( $f->process('abc'), 'abc' );
is( ( $f->proc_by_index(2)->process('ABC') )[0], 'abc' );
is( ( $f->proc_by_index(3)->process('ABC') )[0], 'CBA' );
ok( !defined( $f->proc_by_index(4356) ) );

##############################################################################

$f = DataFlow->new(
    [
        [
            Proc => {
                name => 'first',
                p    => sub { uc }
            }
        ],
        [
            Proc => {
                name => 'second',
                p    => sub { scalar reverse }
            }
        ],
        [
            Proc => {
                name => 'third',
                p    => sub { lc }
            }
        ],
        [
            Proc => {
                name => 'fourth',
                p    => sub { scalar reverse }
            }
        ],
    ]
);
ok($f);

is( $f->process('abc'), 'abc' );
is( ( $f->proc_by_name('third')->process('ABC') )[0],  'abc' );
is( ( $f->proc_by_name('fourth')->process('ABC') )[0], 'CBA' );
ok( !defined( $f->proc_by_name('no ecziste') ) );

