
use Test::More tests => 8;

use_ok('DataFlow::Proc::NOP');
my $nop = new_ok('DataFlow::Proc::NOP');
ok( !defined( $nop->process() ) );

sub nop {
    my $data = shift;
    my $text = shift;
    is_deeply( ( $nop->process($data) )[0], $data, q{Works with } . $text );
}

nop( 'yadayadayada', q{a single scalar, string} );
nop( 42,             q{a single scalar, int} );
nop( [qw/a b c d e f g h i j/], q{an array reference} );
nop( { a => 1, b => 2, c => 3, d => 4 }, q{a hash reference} );
nop(
    [
        qw/ee ff gg hh ii jj kk/,
        {
            deeper => 'structure',
            goes   => [ 'deep', 'rolling', 'under', ],
        },
        'yeah!!!',
    ],
    q{a more complex structure}
);

