use Test::Most;
use List::MoreUtils;

# check (not-) loading of PDL

BEGIN { use_ok 'AI::FuzzyEngine::Set'      };
BEGIN { use_ok 'AI::FuzzyEngine::Variable' };
BEGIN { use_ok 'AI::FuzzyEngine'           };

sub class     { 'AI::FuzzyEngine'           };
sub set_class { 'AI::FuzzyEngine::Set'      };
sub var_class { 'AI::FuzzyEngine::Variable' };

my $class        = class();
my $engine_class = class();
my $set_class    = set_class();
my $var_class    = var_class();

my $PDL_is_loaded = exists $INC{PDL};

subtest "$class constructor" => sub {
    can_ok $class, 'new';
    ok my $fe = $class->new, $class . '->new succeeds';
    isa_ok $fe, $class, 'What it returns';
};

subtest "$class operations" => sub {
    my $fe = $class->new();

    # Disjunction:
    my $a = $fe->or( 0.2, 0.5, 0.8, 0.7 );
    is( $a, 0.8, '"or"' );

    # Conjunction:
    my $b = $fe->and( 0.2, 0.5, 0.8, 0.7 );
    is( $b, 0.2, '"and"' );

    # Negation:
    my $c = $fe->not( 0.4 );
    is( $c, 0.6, '"not"' );

    # True:
    my $t = $fe->true();
    is( $t, 1.0, '"true"' );

    # False:
    my $f = $fe->false();
    is( $f, 0.0, '"false"' );
};

subtest "Class $set_class _copy_fun" => sub {

    my $fun_in  = [[1=>2] => [-1=>1]];
    my $fun_out = $set_class->_copy_fun( $fun_in );
    ok(    ( $fun_out      ne $fun_in     )
        && ($fun_out->[0] ne $fun_in->[0])
        && ($fun_out->[1] ne $fun_in->[1]),
        '_copy_fun copies all references',
       );

    my $fun = [ [10] => [0.5] ];
    $set_class->set_x_limits( $fun, 0 => 1 );
    is_deeply( $fun,
               [ [0, 1] => [0.5, 0.5] ],
               'set_x_limits, single point', 
             );

    $fun = [ [1, 2] => [1, 1] ];
    $set_class->set_x_limits( $fun, 0 => 3 );
    is_deeply( $fun,
               [ [0, 1, 2, 3] => [1, 1, 1, 1] ],
               'set_x_limits, enlarge', 
             );
};

subtest "Class $set_class set_x_limits" => sub {

    my $fun = [ [-1, 4] => [1, 1] ];
    $set_class->set_x_limits( $fun, 0 => 3 );
    is_deeply( $fun,
               [ [0, 3] => [1, 1] ],
               'set_x_limits, reduce', 
             );

    $fun = [ [-0.4, -0.2, 1.2, 1.4] => [0, 1, 1, 0] ];
    $set_class->set_x_limits( $fun, -0.2 => 1.2 );
    is_deeply( $fun,
               [ [-0.2, 1.2] => [1, 1] ],
               'set_x_limits, meet inner points', 
             );

    $fun = [ [-1.2, -1.0, 1.2, 1.4] => [0, 1, 1, 0] ];
    $set_class->set_x_limits( $fun, -0.2 => 0.2 );
    is_deeply( $fun,
               [ [-0.2, 0.2] => [1, 1] ],
               'set_x_limits skip inner points',
             );
};

subtest "Class $set_class synchronize_funs" => sub {

    my $funA = [ [1, 2] => [-1, -2] ];
    my $funB = [ [0, 4] => [-2, -3] ];
    $set_class->synchronize_funs( $funA, $funB );
    is_deeply( $funA->[0], [0, 1, 2, 4], 'synchronize_funs $funA->x' );
    is_deeply( $funB->[0], [0, 1, 2, 4], 'synchronize_funs $funB->x' );
    # y: borders not clipped, so interpol uses border values directly
    is_deeply( $funA->[1], [-1,    -1,   -2, -2],
               'synchronize_funs $funA->y',
             );
    is_deeply( $funB->[1], [-2, -2.25, -2.5, -3],
               'synchronize_funs $funB->y',
             );

    # crossing
    $funA = [ [0, 1] => [0.5,   2] ];
    $funB = [ [0, 1] => [  2, 1.5] ];
    $set_class->synchronize_funs( $funA, $funB );
    is_deeply( $funA,
               [ [0, 0.75, 1] => [0.5, 1.625, 2] ],
               'synchronize_funs $funA with crossing curves',
             );
    is_deeply( $funB,
               [ [0, 0.75, 1] => [2, 1.625, 1.5] ],
               'synchronize_funs $funB with crossing curves',
             );

    $funA = [ [] => [] ];
    $funB = [ [] => [] ];
    throws_ok { $set_class->synchronize_funs( $funA, $funB )
              } qr/is empty/, 'Checks for empty functions';
};

subtest "Class $set_class min & max" => sub {

    my $funA = [ [1, 2] => [-1, -2] ];
    my $funB = [ [0, 4] => [-2, -3] ];
    is_deeply( $set_class->min_of_funs( $funA, $funB ),
               [ [0, 1, 2, 4] => [-2, -2.25, -2.5, -3] ],
               'min_of_funs',
             );
    is_deeply( $set_class->max_of_funs( $funA, $funB ),
               [ [0, 1, 2, 4] => [-1,    -1,   -2, -2] ],
               'max_of_funs',
             );

    my $funC = [ [0, 4] => [-2.75, -2.75] ];
    is_deeply( $set_class->min_of_funs( $funA, $funB, $funC ),
               [ [0, 1, 2, 3, 4] => [-2.75, -2.75, -2.75, -2.75, -3] ],
               'min_of_funs recursively',
             );
};

subtest "Class $set_class clip_fun, centroid" => sub {

    my $funA = [ [0, 1, 2] => [0, 1, 0] ];
    my $funA_clipped = $set_class->clip_fun( $funA => 0.5 );
    is_deeply( $funA_clipped,
               [ [0, 0.5, 1, 1.5, 2] => [0, 0.5, 0.5, 0.5, 0] ],
               'clip_fun',
             );

    my $fun = [ [1, 2] => [1, 1] ];
    my $c   = $set_class->centroid( $fun );
    is( $c, 1.5, 'centroid box' );

    $fun = [ [1, 4] => [0, 1] ];
    $c   = $set_class->centroid( $fun );
    is( $c, 3, 'centroid triangle positive slope' );

    $fun = [ [1, 4] => [1, 0] ];
    $c   = $set_class->centroid( $fun );
    is( $c, 2, 'centroid triangle positive slope' );

    $fun = [ [-2, 0, 0, 3] => [0.75, 0.75, 1, 0] ];
    $c   = $set_class->centroid( $fun );
    is( $c, 0, 'centroid combination, checking area calculation' );
};

my $fe = a_fuzzyEngine();
my %set_pars = ( fuzzyEngine => $fe,
                 variable    => a_variable( $fe ),
                 name        => 'few',
                 memb_fun    => [[7, 8] => [0, 1]],
               );

subtest "$set_class constructor" => sub {

    my $s = $set_class->new(%set_pars);
    isa_ok( $s, $set_class, 'What the constructor returns' );

    is_deeply( [         $s->name, $s->memb_fun, $s->variable, $s->fuzzyEngine],
               [@set_pars{qw(name      memb_fun     variable)},            $fe],
               'Attributes given in the constructor',
           );
};

subtest "$set_class methods" => sub {

    my $s = $set_class->new(%set_pars);
    is( $s->degree, 0, 'Initial (internal) membership degree is 0' );

    $s->degree( 0.2 );
    is( $s->degree, 0.2, 'degree can be set by assignment' );

    $s->degree( 0.1 );
    is( $s->degree, 0.2, 'Disjunction of last and new degree' );

    $s->degree( 0.3, 0.5 );
    is( $s->degree, 0.3, 'Conjunction of multiple inputs ("and" operation)' );

    local $set_pars{memb_fun} = [ [0.2, 0.3, 0.8, 1.0], # x
                                  [0.1, 0.5, 0.5, 0.0], # y
                                ];
    $s = $set_class->new(%set_pars);

    # fuzzify some values
    my @vals     = (  0, 0.2, 0.25, 0.3, 0.5, 0.8, 0.90, 1);
    my @expected = (0.1, 0.1, 0.30, 0.5, 0.5, 0.5, 0.25, 0 );
    my @got      = map { $s->fuzzify($_) } @vals;
    is_deeply( \@got, \@expected,
               'fuzzify incl. corner cases and reset of degree',
             );

    my $degree = $s->fuzzify( 0.2 );
    is( $degree, 0.1, 'fuzzify returns degree' );

    $set_pars{memb_fun} = [ [0, 1, 1, 2] => [1, 2, 3, 4] ];
    throws_ok {$s = AI::FuzzyEngine::Set->new(%set_pars)
              } qr/no double/i, 'Checks double interpolation coordinates';
};

subtest "$set_class special memb_fun methods" => sub {

    # Replace a membership function
    my $s = $set_class->new(%set_pars);
    is_deeply( $s->memb_fun, [[7, 8] => [0, 1]],
               '(preconditions)',
             ) or diag 'Test broken, check precondition';

    my $new_fun = [ [5, 6] => [0.5, 0.7] ];
    $s->replace_memb_fun( $new_fun );
    is_deeply( $s->memb_fun, $new_fun, 'replace_memb_fun' );
    1;
};

subtest "$var_class functions" => sub {

    my $memb_fun = $var_class->_curve_to_fun( [8=>1, 7=>0] );
    is_deeply( $memb_fun, [[7, 8] => [0, 1]], '_curve_to_fun' );

    $memb_fun = $var_class->_curve_to_fun( [] );
    is_deeply( $memb_fun, [[]=>[]], '_curve_to_fun( [] )' );
};

my @var_pars = ( 0 => 10,                   # order is relevant!
                 'low'  => [0, 1, 10, 0],
                 'high' => [0, 0, 10, 1],
               );

subtest "$var_class constructor" => sub {

    my $v  = $var_class->new( $fe, @var_pars );
    isa_ok( $v, $var_class, '$v' );

    is( $v->fuzzyEngine, $fe, 'fuzzyEngine is stored' );
    ok( ! $v->is_internal, 'Variable is not internal' );

    is_deeply( [$v->from, $v->to, [ sort keys %{ $v->sets } ] ],
               [       0,     10, [ sort qw(low high)       ] ],
               'Variable attributes and set names',
             );
};

subtest "$var_class methods" => sub {

    my $v  = $var_class->new( $fe, @var_pars );
    ok(   $v->is_valid_set('high'     ), 'is_valid_set (true) ' );
    ok( ! $v->is_valid_set('wrong_set'), 'is_valid_set (false)' );
};

subtest "$var_class generated sets" => sub {
    my $v  = $var_class->new( $fe, @var_pars );

    my $low_set = $v->sets->{low};
    isa_ok( $low_set, $set_class, 'What variable generates' );
    is_deeply( $low_set->memb_fun,
               [ [0, 10] => [1, 0] ],
               'and receives converted membership functions',
             );

    can_ok( $v, 'low' ); # can_ok needs no description!

    my $degree = $v->low;
    is( $degree, 0, 'initial value for degree of low' );

    $degree = $v->low(0.2, 0.1);
    is( $degree, 0.1, 'and / or for degree of low work' );

    my $w  = $var_class->new( $fe,
                              0 => 2,
                              'low'  => [0, 1],
                              'med'  => [0, 0],
                            );

    # $v and $w have a 'low' function.
    # Are they independent with regard to degree?
    is( $v->low, 0.1, 'degree for low unchanged from other variables' );
    is( $w->low, 0,   'degree for low of the new variable is independent');
};

subtest "$var_class order of sets" => sub {
    my @range        = 0..99;
    my @list_of_sets = map { ("s_$_" => [$_,1]) } @range;

    my $x = $var_class->new( $fe, 0 => 1, @list_of_sets );
    my @indexes      = map {/(\d+)/} $x->set_names;

    no warnings qw(once);
    my @is_same = List::MoreUtils::pairwise {$a==$b} @range, @indexes;
    ok( ( List::MoreUtils::all {$_} @is_same ),
        q{set_names returns the set's names in correct range},
    );
};

subtest "$var_class completing membership functions in x" => sub {

    my $v  = $var_class->new( $fe,
                              0 => 10,
                              'low'  => [ 3, 1,  6, 0],
                              'med'  => [ 5, 0.5],
                              'high' => [ -5, 0, 15, 1],
                            );

    is_deeply( $v->sets->{low}->memb_fun(),
               [ [0, 3, 6, 10] => [1, 1, 0, 0] ],
               'borders of membership funs are adapted to from=>to',
             );

    is_deeply( $v->sets->{med}->memb_fun(),
               [ [0, 10] => [0.5, 0.5] ],
               'even if constant',
             );

    is_deeply( $v->sets->{high}->memb_fun(),
               [ [0, 10] => [0.25, 0.75] ],
               '... limits even when crossing edges',
             );
};

subtest "$var_class change_set" => sub {
    my $v  = $var_class->new( $fe,
                              0 => 10,
                              'low'  => [ 3, 1,  6, 0],
                              # becomes [ [0, 3, 6, 10] => [1, 1, 0, 0] ],
                              'high' => [ -5, 0, 15, 1],
                            );

    $v->fuzzify( 5 ); # $v->low > 0 && $v->high > 0

    my $new_memb_fun = [2, 1, 8, 0];
    $v->change_set( low => $new_memb_fun );

    is_deeply( $v->sets->{low}->memb_fun(),
               [ [0, 2, 8, 10] => [1, 1, 0, 0] ],
               'change_set works and adapts borders in x',
             );

    is_deeply( [$v->low, $v->high], [0, 0], 'change_set resets the variable' );

    throws_ok { $v->change_set( 'wrong_set' )
              } qr/set/i, 'change_set checks correct set name';

    1;
};

subtest "$var_class fuzzification and defuzzification" => sub {

    my $v  = $var_class->new( $fe,
                              0 => 10,
                              'low'  => [ 3, 1,  6, 0],
                              'med'  => [ 5, 0.5],
                              'high' => [ -5, 0, 15, 1],
                            );

    $v->fuzzify( 0 );
    is_deeply( [$v->low, $v->med, $v->high],
               [      1,     0.5,     0.25],
               'fuzzify fuzzifies all sets',
             );

    $v->fuzzify( 10 );
    is_deeply( [$v->low, $v->med, $v->high],
               [      0,     0.5,     0.75],
               'fuzzify resets and fuzzifies all sets',
             );

    # Defuzzification
    $v = AI::FuzzyEngine::Variable
        ->new( $fe,
               0 => 2,
               low  => [0 => 1, 1 => 1, 1.00001 => 0, 2 => 0],
               high => [0 => 0, 1 => 0, 1.00001 => 1, 2 => 1],
             );

    $v->low(  1 ); # explicit control for next tests
    $v->high( 0 );
    my $val = sprintf "%.2f", $v->defuzzify();
    is( $val*1, 0.5, 'defuzzy low' );

    $v->reset;
    $v->low(  0 );
    $v->high( 0.5 );
    $val = sprintf "%.2f", $v->defuzzify();
    is( $val*1, 1.5, 'defuzzy high' );

    $v->low( 1 );
    $val = $v->defuzzify();
    ok( ($val > 0.5 && $val < 1), 'defuzzy low + 0.5*high' );
};

my @int_var_pars = ( # $from => $to MISSING --> internal
                     'low'  => [0, 1, 10, 0],
                     'high' => [0, 0, 10, 1],
                   );

subtest "$var_class (internal) constructor" => sub {

    my $v  = $var_class->new( $fe, @int_var_pars );
    isa_ok( $v, $var_class, '$v' );

    is( $v->fuzzyEngine, $fe, 'fuzzyEngine is stored' );
    ok( $v->is_internal, 'Variable is internal' );
    is( ref( $v->sets), 'HASH', 'sets is a HashRef' );

    is_deeply( [$v->from, $v->to, [ sort keys %{ $v->sets } ] ],
               [   undef,  undef, [ sort qw(low high)       ] ],
               'Variable attributes and set names',
             );
};

subtest "$var_class (internal) methods" => sub {

    my $v  = $var_class->new( $fe, @int_var_pars );
    ok(   $v->is_valid_set('high'     ), 'is_valid_set (true) ' );
    ok( ! $v->is_valid_set('wrong_set'), 'is_valid_set (false)' );

    my $low_set = $v->set('low');
    isa_ok( $low_set, $set_class, 'What variable->set returns' );
    is_deeply( $low_set->memb_fun,
               [[]=>[]],
               'Membership function is empty',
             );

    can_ok( $v, 'low' );

    my $degree = $v->low;
    is( $degree, 0, 'initial value for degree of low' );

    $degree = $v->low(0.2, 0.1);
    is( $degree, 0.1, 'and / or for degree of low work' );

    $v->reset;
    is( $v->low, 0, 'reset works' );

    # Throw errors!
    throws_ok { $v->fuzzify(0)
              } qr/internal/, 'Checks illegal fuzzify call';
    throws_ok { $v->defuzzify
              } qr/internal/, 'Checks illegal defuzzify call';
    throws_ok { $v->change_set( low => [[]=>[]] )
              } qr/internal/i, 'Blocks change_set';
};

$fe = $class->new();

subtest "$class as factory" => sub {

    my $v = $fe->new_variable( 0 => 10,
                               'low'  => [0, 1, 10, 0],
                               'high' => [0, 0, 10, 1],
                             );
    isa_ok( $v, $var_class, 'What $fe->new_variable returns' );
    is_deeply( [$v->from, $v->to, [ sort keys %{ $v->sets } ] ],
               [       0,     10, [ sort qw(low high)       ] ],
               'Variable attributes and set names by new_variable',
             );

    my $w = $fe->new_variable( 0 => 1,
                               'low'  => [0, 1],
                               'high' => [1, 0],
                             );

    is_deeply( [ $fe->variables() ],
               [$v, $w],
               'Engine stores variables (should be weakened)',
             );

    $v->low( 0.1 );
    $w->low( 0.2 );

    my $v_resetted = $v->reset;
    isa_ok( $v_resetted,
            $var_class,
            'What variable->reset returns',
          ) or exit;
    is( $v->low, 0.0, 'Variable can be resetted'       );
    is( $w->low, 0.2, 'Other variables stay unchanged' );

    my $fe_resetted = $fe->reset();
    isa_ok( $fe_resetted,
            $class,
            'What fuzzyEngine->reset returns',
          );
    is( $w->low, 0.0, 'FuzzyEngine resets all variables' );
};

subtest 'synopsis' => sub {

    # Engine (or factory) provides fuzzy logical arithmetic
    my $fe = $class->new();

    # Disjunction:
    my $a = $fe->or ( 0.2, 0.5, 0.8, 0.7 ); # 0.8
    # Conjunction:
    my $b = $fe->and( 0.2, 0.5, 0.8, 0.7 ); # 0.2
    # Negation:
    my $c = $fe->not( 0.4 );                # 0.6
    # Always true:
    my $t = $fe->true();                    # 1.0
    # Always false:
    my $f = $fe->false();                   # 0.0

    # These functions are constitutive for the operations
    # on the fuzzy sets of the fuzzy variables:

    # VARIABLES (AI::FuzzyEngine::Variable)

    # input variables need definition of membership functions of their sets
    my $flow = $fe->new_variable( 0 => 2000,
                        small => [0, 1,  500, 1, 1000, 0                  ],
                        med   => [       400, 0, 1000, 1, 1500, 0         ],
                        huge  => [               1000, 0, 1500, 1, 2000, 1],
                   );
    my $cap  = $fe->new_variable( 0 => 1800,
                        avg   => [0, 1, 1500, 1, 1700, 0         ],
                        high  => [      1500, 0, 1700, 1, 1800, 1],
                   );
    # internal variables need sets, but no membership functions
    my $saturation = $fe->new_variable( # from => to may be ommitted
                        low   => [],
                        crit  => [],
                        over  => [],
                   );
    # But output variables need membership functions for their sets:
    my $green = $fe->new_variable( -5 => 5,
                        decrease => [-5, 1, -2, 1, 0, 0            ],
                        ok       => [       -2, 0, 0, 1, 2, 0      ],
                        increase => [              0, 0, 2, 1, 5, 1],
                   );

    # Reset FuzzyEngine (resets all variables)
    $fe->reset();

    # Reset a fuzzy variable directly
    $flow->reset;

    # Membership functions can be changed via the set's variable.
    # This might be useful during parameter identification algorithms
    # Changing a function resets the respective variable.
    $flow->change_set( med => [500, 0, 1000, 1, 1500, 0] );

    # Fuzzification of input variables
    $flow->fuzzify( 600 );
    $cap->fuzzify( 1000 );

    # Membership degrees of the respective sets are now available:
    my $flow_is_small = $flow->small(); # 0.8
    my $flow_is_med   = $flow->med();   # 0.2
    my $flow_is_huge  = $flow->huge();  # 0.0

    # RULES and their application

    # a) first step, result is $saturation, an intermediate set
    # implicit application of 'and'
    # Multiple calls to a membership function
    # are similar to 'or' operations:
    $saturation->low( $flow->small(), $cap->avg()  );
    $saturation->low( $flow->small(), $cap->high() );
    $saturation->low( $flow->med(),   $cap->high() );

    # Explicite 'or', 'and' or 'not' possible:
    $saturation->crit( $fe->or( $fe->and( $flow->med(),  $cap->avg()  ),
                                $fe->and( $flow->huge(), $cap->high() ),
                       ),
                 );

    $saturation->over( $fe->not( $flow->small() ),
                       $fe->not( $flow->med()   ),
                       $flow->huge(),
                       $cap->high(),
                 );
    $saturation->over( $flow->huge(), $fe->not( $cap->high() ) );

    # b) second step, deduce output variable from internal state of saturation
    $green->decrease( $saturation->low()  );
    $green->ok(       $saturation->crit() );
    $green->increase( $saturation->over() );

    # All sets provide the respective membership degrees of their variables: 
    my $saturation_is_over = $saturation->over(); # no defuzzification!
    my $green_is_ok        = $green->ok();

    # Defuzzification ( is a matter of the fuzzy set )
    my $delta_green = $green->defuzzify(); # -5 ... 5

    ok( 1, 'POD synopsis' );
};

subtest 'PDL may not be loaded' => sub {
    if ($PDL_is_loaded) {
        diag "PDL was loaded at start of test - check not possible";
    }
    else {
        ok( (not exists $INC{PDL}), 'Module does not load PDL' );
    };
};

done_testing();

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

sub a_fuzzyEngine { return class()->new() }

1;
