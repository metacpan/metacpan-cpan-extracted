use Test::Most;
use List::MoreUtils;

use AI::FuzzyEngine::Set;
use AI::FuzzyEngine::Variable;
use AI::FuzzyEngine;

sub class     { 'AI::FuzzyEngine'           };
sub set_class { 'AI::FuzzyEngine::Set'      };
sub var_class { 'AI::FuzzyEngine::Variable' };

my $class        = class();
my $set_class    = set_class();
my $var_class    = var_class();

# Can PDL be loaded? skip_all if not.
my $module = 'PDL';
my $msg    = qq{Cannot find $module. }
           . qq{$class is not $module aware on your computer};
if (not eval "use $module; 1") { plan skip_all => $msg };

subtest "$class internal functions" => sub {

    # _cat_array_of_piddles

    my @vals = (0..2);
    my $vals = $class->_cat_array_of_piddles(@vals);
    is( $vals->ndims, 1, 'ndims of cat topdl with scalars');
    ok_all( $vals == pdl( [ 0, 1, 2 ] ),
            'cat topdl with scalars',
          );

    @vals = map {pdl([$_])} (0..2);
    $vals = $class->_cat_array_of_piddles(@vals);
    is( $vals->ndims, 2, 'ndims of cat topdl with pdl([scalar])' );
    ok_all( $vals == pdl( [ [0], [1], [2], ] ),
            'cat topdl with scalars',
          );

    @vals = map {pdl([[$_, 1], [7]])} (0..2);
    $vals = $class->_cat_array_of_piddles(@vals);
    is( $vals->ndims, 3, 'cat of 2dim' );

    @vals =( 6, pdl( [[5, 7], [1, 2]] ) );
    $vals = $class->_cat_array_of_piddles(@vals);
    ok_all( $vals == pdl( [[6, 6], [6, 6]],
                          [[5, 7], [1, 2]],
                        ),
            'cat topdl scalar, 2dim 4elem pdl',
          ) or diag $vals;

    @vals = ( pdl([[11],[21]]), pdl([[11, 12]]));
    $vals = $class->_cat_array_of_piddles(@vals);
    ok_all( $vals == pdl( [[11, 11], [21, 21]],
                          [[11, 12], [11, 12]],
                        ),
            'cat topdl two 2dim 4elem pdls',
          ) or diag $vals;

    @vals = ( pdl([1]), pdl([]) );
    throws_ok { $class->_cat_array_of_piddles(@vals)
              } qr/empty/i,
                  '_cat_array_of_piddles checks for empty piddles';

};

subtest "$class PDL operations" => sub {
    my $fe = $class->new();

    # Negation:
    my $c = $fe->not( 0.4 );
    ok( ref $c eq '', 'not scalar: scalar' );
    ok( $c == 0.6,    'not scalar: result' );

    $c = $fe->not( pdl( 0.4 ) );
    isa_ok( $c, 'PDL', 'not(PDL scalar)'         );
    ok( $c == 0.6,     'not(PDL scalar): result' );

    $c = $fe->not( pdl([0.4, 0.5], [0, 1]) );
    isa_ok( $c, 'PDL',                     'not(PDL 2elem)'         );
    ok_all( $c == pdl([0.6, 0.5], [1, 0]), 'not(PDL 2elem): result' );

    # And and or use _cat_array_of_piddles
    # to bring input to the same dimensions
    # And
    $c = $fe->and( 0.4, pdl( [0.5] ) );
    isa_ok( $c, 'PDL', 'and(scalar, PDL)'         );
    ok_all( $c == 0.4, 'and(scalar, PDL): result' );

    $c = $fe->and( 0.6, pdl( [0.5, 0.7] ) );
    isa_ok( $c, 'PDL',             'and(scalar, 2elem PDL)'         );
    ok_all( $c == pdl([0.5, 0.6]), 'and(scalar, 2elem PDL): result' );

    # Or
    $c = $fe->or( 0.4, pdl( [0.5] ) );
    isa_ok( $c, 'PDL', 'or(scalar, PDL)'         );
    ok_all( $c == 0.5, 'or(scalar, PDL): result' );

    $c = $fe->or( 0.6, pdl( [0.5, 0.7] ) );
    isa_ok( $c, 'PDL',             'or(scalar, 2elem PDL)'         );
    ok_all( $c == pdl([0.6, 0.7]), 'or(scalar, 2elem PDL): result' );
};

my $fe = a_fuzzyEngine();
my %set_pars = ( fuzzyEngine => $fe,
                 variable    => a_variable( $fe ),
                 name        => 'few',
                 memb_fun    => [[7, 8] => [0, 1]],
               );

subtest "$set_class PDL degree" => sub {

    my $s = $set_class->new(%set_pars);
    is( $s->degree, 0, 'Initial (internal) membership degree is 0' );

    $s->degree( pdl(0.2) );
    is( $s->degree, 0.2, 'degree can be set by assignment of a piddle' );
    isa_ok( $s->degree, 'PDL', '$s->degree' );

    $s->degree( 0.1 );
    is( $s->degree, 0.2, 'Disjunction of last and new degree (1)' );

    $s->degree( 0.3 );
    is( $s->degree, 0.3, 'Disjunction of last and new degree (2)' );
    isa_ok( $s->degree, 'PDL', '$s->degree after recalculation' );

    $s->reset();
    is( ref $s->degree, '', 'reset makes degree a scalar again' );

    $s->degree( 0.3, pdl([0.5, 0.2]) );
    ok_all( $s->degree == pdl([0.3, 0.2] ),
            'Conjunction of multiple inputs ("and" operation)',
          );

    local $set_pars{memb_fun} = pdl( [[7, 8] => [0, 1]] );
    throws_ok{ $set_class->new(%set_pars)
             } qr/array ref/, 'Checks pureness of membership function';

};

subtest "$set_class PDL _interpol & fuzzify" => sub {

    local $set_pars{memb_fun} = [ [0.2, 0.3, 0.8, 1.0], # x
                                  [0.1, 0.5, 0.5, 0.0], # y
                                ];
    my $s = $set_class->new(%set_pars);

    # fuzzify some values
    # (no extrapolation in this test case)
    my $x        = pdl(0.2, 0.25, 0.3, 0.5, 0.8, 0.90, 1);
    my $expected = pdl(0.1, 0.30, 0.5, 0.5, 0.5, 0.25, 0 );
    my $got      = $s->fuzzify( $x );

    isa_ok( $got, 'PDL', 'What fuzzify (_interpol) returns' );
    ok_all( $got == $expected, 'fuzzify' ) or diag $got;
};

subtest "$var_class fuzzification with piddles" => sub {

    my $v  = $var_class->new( $fe,
                              0 => 10,
                              'low'  => [ 3, 1,  6, 0],
                              'med'  => [ 5, 0.5],
                              'high' => [ -5, 0, 15, 1],
                            );

    my $vals = pdl( [10, 5]);
    $v->fuzzify( $vals );

    isa_ok( $v->low, 'PDL', 'What $v->low returns' );

    ok_all( $v->low  == pdl([  0, 1/3]), '$v->low'  ); # :-))
    ok_all( $v->med  == pdl([0.5, 0.5]), '$v->med'  );
    ok_all( $v->high == pdl([3/4, 1/2]), '$v->high' );
};

subtest "$var_class defuzzification with piddles" => sub {

    my $v = AI::FuzzyEngine::Variable
        ->new( $fe,
               0 => 2,
               low  => [0 => 1, 1 => 1, 1.00001 => 0, 2 => 0],
               high => [0 => 0, 1 => 0, 1.00001 => 1, 2 => 1],
             );

    $v->low(  pdl(1, 0, 1) );
    $v->high( 0.5 ); # non pdl

    my $val = $v->defuzzify;
    isa_ok( $val, 'PDL', 'What $v->defuzzify returns from scalar+pdl' );
    my @size = $val->dims;
    is_deeply( \@size, [3], 'dimensions' );

    $v->reset;
    $v->low(  pdl(1, 0, 1) );
    $v->high( pdl(0, 0.5, 0.5) );
    my $val_got = $v->defuzzify;
    my $val_exp = pdl( 0.5, 1.5, 0.83 );
    ok_all( abs($val_got-$val_exp) < 0.1, 'defuzzify a piddle' );

    # Performance: Run testfile by nytprofiler
    $v->reset;
    my $n =100;
    $v->low(  random($n) );
    $v->high( 1-$v->low  );
    lives_ok { $val_got = $v->defuzzify; } "Defuzzifying $n elements";
};

subtest 'PDL synopsis' => sub {
#    use PDL;
#    use AI::FuzzyEngine;

    # (Probably a stupide example)
    my $fe       = AI::FuzzyEngine->new();

    # Declare variables as usual
    my $severity  = $fe->new_variable( 0 => 10,
                          low  => [0, 1, 3, 1, 5, 0       ],
                          high => [      3, 0, 5, 1, 10, 1],
                        );

    my $threshold = $fe->new_variable( 0 => 1,
                           low  => [0, 1, 0.2, 1, 0.8, 0,     ],
                           high => [      0.2, 0, 0.8, 1, 1, 1],
                         );
    my $problem   = $fe->new_variable( -0.5 => 2,
                           no  => [-0.5, 0, 0, 1, 0.5, 0, 1, 0],
                           yes => [         0, 0, 0.5, 1, 1, 1, 1.5, 1, 2, 0],
                         );

    # Input data is a pdl of arbitrary dimension
    my $data = pdl( [0, 4, 6, 10] );
    $severity->fuzzify( $data );

    # Membership degrees are piddles now: 
#    print 'Severity is high: ', $severity->high, "\n";
    # [0 0.5 1 1]

    # Other variables might be a piddle of other dimensions,
    # but variables must be extensible to a common 'wrapping' piddle
    # ( in this case a 4x2 matrix with 4 colums and 2 rows)
    my $level = pdl( [0.6],
                     [0.2],
                   );
    $threshold->fuzzify( $level );

#    print 'Threshold is low: ', $threshold->low(), "\n";
    # [
    #  [0.33333333]
    #  [         1]
    # ]

    # Apply the rule base
    # --> no for loops, no explicit expansion, ...
    $problem->yes( $severity->high,  $threshold->low );
    $problem->no( $fe->not( $problem->yes )  );

#    print 'Problem yes: ', $problem->yes,  "\n";
    # [
    #  [         0 0.33333333 0.33333333 0.33333333]
    #  [         0        0.5          1          1]
    # ]

    # Defuzzify the output variables
    # Caveat: This includes some non-threadable operations up to now
    my $problem_ratings = $problem->defuzzify();
#    print 'Problems rated: ', $problem_ratings;
    # [
    #  [         0 0.60952381 0.60952381 0.60952381]
    #  [         0       0.75          1          1]
    # ]

    ok( 1, 'POD synopsis' );
};

done_testing();

sub ok_all {
    my ($p, $descr) = @_;
    die 'First arg must be a piddle' unless ref $p eq 'PDL';
    ok(  $p->all() , $descr || '' );
}

sub a_variable {
    # Careful!
    # a_variable does not register its result into $fuzzyEngine.
    # ==> is missing in $fe->variables;
    #
    my ($fuzzyEngine, @pars) = @_;
    my $v = var_class()->new( $fuzzyEngine,
                              0 => 1,
                              'low'  => [0, 0],
                              'high' => [1, 1],
                              @pars,
                            );
    return $v;
}

sub a_fuzzyEngine { return $class->new() }

1;
