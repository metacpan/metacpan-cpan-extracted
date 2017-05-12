use strict;
use warnings;
use Test::More;

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

note('The next check emits an error intentionally; this is ok.');

# Construction
eval "
    package Class::Lite;
    use Class::Lite qw| attr1 attr2 attr3 |;
";
$eval_err       = $@;
$want           = qr/Recursive inheritance/;
$check          = 'recursive inheritance';
like( $eval_err, $want, $check );
note($eval_err);




END {
    done_testing();
};
exit 0;

