use strict;
use warnings;
use Test::More;
use Module::Empty;              # Truly empty module ships with Class::Lite

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

note('The next check emits an error intentionally; this is ok.');

# Construction
eval "
    package Module::Empty;
    use Class::Lite ( 'attr1', [ 1, 2, 3 ], 'attr3' );
";

$eval_err       = $@;
$want           = qr/Invalid accessor name/;
$check          = 'Invalid accessor name (undef)';
like( $eval_err, $want, $check );
note($eval_err);



END {
    done_testing();
};
exit 0;

