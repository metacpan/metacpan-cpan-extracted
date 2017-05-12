use strict;
use warnings;
use Test::More;

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

note('This script emits several errors intentionally; this is ok.');

# Construction
eval q{
    package Module::Empty;
    use Class::Lite qw| attr1 ho-ge attr3 |;
};

$eval_err       = $@;
$want           = qr/Invalid accessor name/;
$check          = 'Invalid accessor name (ho-ge)';
like( $eval_err, $want, $check );
note($eval_err);

eval q{
    package Module::Empty::Bear;
    use Class::Lite ( 'attr1', '', 'attr3' );
};

$eval_err       = $@;
$want           = qr/Invalid accessor name/;
$check          = 'Invalid accessor name (empty string)';
like( $eval_err, $want, $check );
note($eval_err);

eval q{
    package Module::Empty::Bird;
    my $wing    = [];
    use Class::Lite ( 'attr1', $wing, 'attr3' );
};

$eval_err       = $@;
$want           = qr/Invalid accessor name/;
$check          = 'Invalid accessor name (aryref)';
like( $eval_err, $want, $check );
note($eval_err);

eval q{
    package Module::Empty::Toad;
    my $legs    = 'string';
    use Class::Lite ( 'attr1', $legs, 'attr3' );
};

$eval_err       = $@;
$want           = qr/Invalid accessor name/;
$check          = 'Invalid accessor name (variable)';
like( $eval_err, $want, $check );
note($eval_err);


exit 0;



END {
    done_testing();
};
exit 0;

