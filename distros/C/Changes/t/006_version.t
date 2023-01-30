#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes::Version' );
};

use strict;
use warnings;

my $v = Changes::Version->new(
    major => 1,
    minor => 2,
    patch => 3,
    alpha => 4,
    qv => 1,
    debug => $DEBUG,
);
isa_ok( $v, 'Changes::Version' );
my $orig = $v->clone;

# To generate this list:
# egrep -E '^sub ' ./lib/Changes/Version.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$v, ''$m'' );"'
can_ok( $v, 'alpha' );
can_ok( $v, 'as_string' );
can_ok( $v, 'beta' );
can_ok( $v, 'compat' );
can_ok( $v, 'dec' );
can_ok( $v, 'dec_alpha' );
can_ok( $v, 'dec_beta' );
can_ok( $v, 'dec_major' );
can_ok( $v, 'dec_minor' );
can_ok( $v, 'dec_patch' );
can_ok( $v, 'default_frag' );
can_ok( $v, 'extra' );
can_ok( $v, 'inc' );
can_ok( $v, 'inc_alpha' );
can_ok( $v, 'inc_beta' );
can_ok( $v, 'inc_major' );
can_ok( $v, 'inc_minor' );
can_ok( $v, 'inc_patch' );
can_ok( $v, 'is_alpha' );
can_ok( $v, 'is_qv' );
can_ok( $v, 'major' );
can_ok( $v, 'minor' );
can_ok( $v, 'normal' );
can_ok( $v, 'numify' );
can_ok( $v, 'original' );
can_ok( $v, 'padded' );
can_ok( $v, 'parse' );
can_ok( $v, 'patch' );
can_ok( $v, 'pretty' );
can_ok( $v, 'qv' );
can_ok( $v, 'rc' );
can_ok( $v, 'reset' );
can_ok( $v, 'target' );
can_ok( $v, 'type' );

my $v2 = $v->clone;
isa_ok( $v2 => 'Changes::Version', 'clone' );
is( $v->as_string, "v1.2.3_4", 'as_string -> v1.2.3_4' );
$v->inc( 'alpha' );
is( $v->as_string, "v1.2.3_5", 'increase alpha -> v1.2.3_5' );
$v->inc( 'patch' );
is( $v->as_string, "v1.2.4", 'increase patch -> v1.2.4' );
$v->inc( 'minor' );
is( $v->as_string, "v1.3.0", 'increase minor -> v1.3.0' );
$v->inc( 'major' );
is( $v->as_string, "v2.0.0", 'increase major -> v2.0.0' );
$v2->type( 'decimal' );
is( $v2->as_string, '1.002003_4', 'dotted decimal to decimal -> 1.002003_4' );
my $v_norm = $v2->normal;
isa_ok( $v_norm => 'Changes::Version' );
is( "$v_norm", 'v1.2.3_4', "normal returns object version $v2 -> v1.2.3_4" );
my $v_num = $v2->numify;
isa_ok( $v_num => 'Changes::Version' );
is( "$v_num", '1.002003_4', "numify returns object $v_norm into version -> 1.002003_4" );

my $vnum = $orig->clone;
$vnum->type( 'decimal' );
is( "$vnum", '1.002003_4', 'decimal -> 1.002003_4' );
$vnum->pretty(1);
# Same because pretty is ineffective when an alpha value (with underscore) is set. It is conflicting in formatting
is( "$vnum", '1.002003_4', 'pretty -> 1.002003_4' );
$vnum->alpha( undef );
is( "$vnum", '1.002_003', 'decimal -> 1.002_003' );
$vnum->patch(0);
is( "$vnum", '1.002_000', 'decimal padded -> 1.002_000' );
$vnum->padded(0);
is( "$vnum", '1.002', 'decimal not padded -> 1.002' );
$vnum->patch(undef);
$vnum->padded(1);
is( "$vnum", '1.200', 'decimal padded -> 1.200' );
$vnum->padded(0);
is( "$vnum", '1.2', 'decimal not padded -> 1.2' );

$v = $orig->clone;
# Starting with v1.2.3_4
my $vn = $orig->clone;
$vn->type( 'decimal' );
# Order is: major minor patch and alpha
my $long_fraction = ( 2 / 3 );
my $tests_dict = {
    dotted => [
    '+' => { version => $v, operand => 1, expect => [qw( v2.0.0 v1.3.0 v1.2.4 v1.2.3_5 )] },
    '-' => { version => $v, operand => 1, expect => [qw( v0.0.0 v1.1.0 v1.2.2 v1.2.3_3 )] },
    '*' => { version => $v, operand => 2, expect => [qw( v2.0.0 v1.4.0 v1.2.6 v1.2.3_8 )] },
    '/' => { version => 'v3.2.1_6', operand => 2, expect => [qw( v1.0.0 v3.1.0 v3.2.0 v3.2.1_3 )] },
    '+=' => { version => $v, operand => 1, expect => [qw( v2.0.0 v1.3.0 v1.2.4 v1.2.3_5 )] },
    '-=' => { version => $v, operand => 1, expect => [qw( v0.0.0 v1.1.0 v1.2.2 v1.2.3_3 )] },
    '*=' => { version => $v, operand => 2, expect => [qw( v2.0.0 v1.4.0 v1.2.6 v1.2.3_8 )] },
    '/=' => { version => $v, operand => 2, expect => [qw( v0.0.0 v1.1.0 v1.2.1 v1.2.3_2 )] },
    '++' => { version => $v, expect => [qw( v2.0.0 v1.3.0 v1.2.4 v1.2.3_5 )] },
    '--' => { version => $v, expect => [qw( v0.0.0 v1.1.0 v1.2.2 v1.2.3_3 )] },
    ],
    decimal => [
    '+' => { version => $vn, operand => 1, expect => [qw( 2.000000 1.003000 1.002004 1.002003_5 )] },
    '-' => { version => $vn, operand => 1, expect => [qw( 0.000000 1.001000 1.002002 1.002003_3 )] },
    '*' => { version => $vn, operand => 2, expect => [qw( 2.000000 1.004000 1.002006 1.002003_8 )] },
    '/' => { version => '3.002001_6', operand => 2, expect => [qw( 1.000000 3.001000 3.002000 3.002001_3 )] },
    '+=' => { version => $vn, operand => 1, expect => [qw( 2.000000 1.003000 1.002004 1.002003_5 )] },
    '-=' => { version => $vn, operand => 1, expect => [qw( 0.000000 1.001000 1.002002 1.002003_3 )] },
    '*=' => { version => $vn, operand => 2, expect => [qw( 2.000000 1.004000 1.002006 1.002003_8 )] },
    '/=' => { version => $vn, operand => 2, expect => [qw( 0.000000 1.001000 1.002001 1.002003_2 )] },
    '++' => { version => $vn, expect => [qw( 2.000000 1.003000 1.002004 1.002003_5 )] },
    '--' => { version => $vn, expect => [qw( 0.000000 1.001000 1.002002 1.002003_3 )] },
    ],
    # Same as for $tests, but with operands swapped
    swapped => [
    '+' => { version => $v, operand => 1, expect => [qw( 2 3 4 5 )], swapped => 1 },
    '-' => { version => $v, operand => 1, expect => [qw( 0 -1 -2 -3 )], swapped => 1 },
    '*' => { version => $v, operand => 2, expect => [qw( 2 4 6 8 )], swapped => 1 },
    '/' => { version => $v, operand => 2, expect => [( 2, 1, $long_fraction, 0.5 )], swapped => 1 },
    # Those will not work
#     '+=' => { version => $v, operand => 1, expect => [qw( )] },
#     '-=' => { version => $v, operand => 1, expect => [qw( )] },
#     '*=' => { version => $v, operand => 2, expect => [qw( )] },
#     '/=' => { version => $v, operand => 2, expect => [qw( )] },
#     '++' => { version => $v, expect => [qw( )] },
#     '--' => { version => $v, expect => [qw( )] },
    ],
};

my $frag2pos =
{
    major => 0,
    minor => 1,
    patch => 2,
    alpha => 3,
};

# foreach my $type ( qw( dotted decimal ) )
foreach my $type ( sort( keys( %$tests_dict ) ) )
{
    subtest $type => sub
    {
        my $tests = $tests_dict->{ $type };
        for( my $i = 0; $i < scalar( @$tests ); $i += 2 )
        {
            my $op = $tests->[$i];
            my $def = $tests->[$i+1];
            $def->{swapped} //= 0;
            my $vers;
            if( ref( $def->{version} ) )
            {
                $vers = $def->{version}->clone;
            }
            else
            {
                $vers = Changes::Version->new( $def->{version}, debug => $DEBUG );
            }
            my $orig = $vers->clone;
            foreach my $frag (qw( major minor patch alpha ))
            {
                diag( "Using version '$vers' for test of type '$type' with fragment '$frag' and with operator '$op'" ) if( $DEBUG );
                my $expect = $def->{expect}->[ $frag2pos->{ $frag } ];
                $vers->default_frag( $frag );
                my $eval;
                if( $def->{swapped} )
                {
                    $eval = "$def->{operand} ${op} \$vers";
                }
                else
                {
                    $eval = "\$vers" . ( exists( $def->{operand} ) ? " ${op} $def->{operand}" : $op );
                }
                my $rv = eval( $eval );
                if( $@ )
                {
                    fail( "Failed $eval: $@" );
                }
                elsif( ref( $rv ) )
                {
                    isa_ok( $rv => 'Changes::Version', "$eval returns a Changes::Version object" );
                }
        
                # ++, --
                if( !exists( $def->{operand} ) )
                {
                    is( "$vers" => $expect, "${orig}${op} -> ${expect}" );
                }
                # Others returns a new object
                else
                {
                    is( "$rv" => $expect, ( $def->{swapped} ? "$def->{operand} ${op} ${orig}" : "${orig} ${op} $def->{operand}" ) . " -> ${expect} (using $frag)" );
                }
                $vers = $orig->clone;
            }
        }
    };
}



done_testing();

__END__

