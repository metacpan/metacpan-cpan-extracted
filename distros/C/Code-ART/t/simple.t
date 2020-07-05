use Test::More;

plan tests => 3;

use Code::ART;

use if $^V >= v5.20, feature => 'signatures';
 no if $^V >= v5.20, warnings => 'experimental::signatures';

my $CODE = qq{
    use $^V;
    our \$name = 'NAME';
    my \$ID    = 99999;
    my %data  = ( a => 0, z => [ 26 ] );
    my \@list  = ( 1..5 );

    my \@copy = \@list;
    my \@result
#=========================
        = ( \$copy[2], \@data{'a','z'}, \${ID}, \$::name );
#=========================
};

my @expected_result = ( 3, 0, [26], 99999, 'NAME' );

my ($prefix, $postfix) = split(/^\s*\#=+\n \K .*? (?=^\s*\#=+\n) /xms, $CODE);
my $from = length($prefix);
my $to   = length($CODE) - length($postfix) - 1;

#diag substr($CODE, 0, $from);
#diag 'vvvvvvvvvvv';
#diag substr($CODE, $from, $to-$from+1);
#diag '^^^^^^^^^^^';
#diag substr($CODE, $to+1);

my $refactoring = refactor_to_sub( $CODE, { from => $from, to => $to } );

#diag $refactoring->{code};
#diag $refactoring->{call};

is_deeply [eval $CODE], \@expected_result => 'Original code produces expected result';

my @refactored_result = eval "$refactoring->{code} $prefix $refactoring->{call} $postfix";
if ($@) { fail 'Refactored code not not execute: '. $@; }
else    { pass 'Refactored code executed'; }

is_deeply \@refactored_result, \@expected_result => 'Correct results';

done_testing();


