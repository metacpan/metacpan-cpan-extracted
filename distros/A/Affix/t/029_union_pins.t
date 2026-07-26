use v5.40;
use blib;
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
#
typedef MyUnion => Union [ i => Int, f => Float ];

# Allocate some memory for the union
my $mem = malloc( sizeof( MyUnion() ) );
my $u   = cast( $mem, MyUnion() );

# $u should be an Affix::Live object
ok is_pin( \$u->{i} ), 'member i is a Pin';
ok is_pin( \$u->{f} ), 'member f is a Pin';

# Write to one, check the other
$u->{i} = 0x3f800000;    # 1.0 in float
is $u->{f}, float(1.0), 'Writing to i affected f';

# Write to f, check i
$u->{f} = 2.0;
is $u->{i}, 0x40000000, 'Writing to f affected i';
#
done_testing;
