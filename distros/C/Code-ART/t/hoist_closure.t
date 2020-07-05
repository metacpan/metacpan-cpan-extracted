use warnings;
use Code::ART;
use Test::More;

use if $^V >= v5.20, feature => 'signatures';
 no if $^V >= v5.20, warnings => 'experimental::signatures';

my $CODE = qq{
    use $^V;
    my \$data = 9;
    my \$totallen = 0;
    no warnings 'redefine';
    sub count {
        \$totallen += shift;
    }
    count( length(\$data) );
    {
        count(length(\$data));
        my \$data = \$data;
        count(length(\$data));
    }
    count(
#=========================
    length(\$data)
#=========================
)
;
    \$totallen;
};

my ($prefix, $postfix) = split(/^\s*\#=+\n \K .*? (?=^\s*\#=+\n) /xms, $CODE);
my $from = length($prefix);
my $to   = length($CODE) - length($postfix) - 1;

my $refactoring = hoist_to_lexical( $CODE, { closure=>1, from => $from, to => $to, all=>1 } );

#diag $refactoring->{code};
#diag $refactoring->{call};

is eval($CODE), 4  => 'Original returned expected value';

my $REFACTORED = $CODE;
my %matchpos = map { $_->{from} => $_->{length} } @{$refactoring->{matches}};
$REFACTORED =~ s{ (??{ exists $matchpos{pos()} ? ".{$matchpos{pos()}}" : '(?!)' }) }
                {$refactoring->{call}}gxms;
substr($REFACTORED, $refactoring->{hoistloc}, 0) = $refactoring->{code};

#diag $REFACTORED;

is eval($REFACTORED), 4  => 'Refactored returned expected value';

done_testing();




