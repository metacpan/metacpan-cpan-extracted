# $Id: properties.t 28 2007-10-29 17:35:27Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/class-dot/t/properties.t $
# $Revision: 28 $
# $Date: 2007-10-29 18:35:27 +0100 (Mon, 29 Oct 2007) $
use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );
use lib 'lib';
use lib $Bin;
use lib 't';
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS = 17;

plan( tests => $THIS_TEST_HAS_TESTS );

use_ok('TestComplete');

# ### TestComplete::Type1
my $type1_no1 = TestComplete->new({
    type => 'Type1',
    from_base => 'this property lives in base',
    in_type1  => 'this property belongs to Type1',
});
isa_ok($type1_no1, 'TestComplete::Type1');

is( $type1_no1->from_base, 'this property lives in base',
    'type1 no1 from_base',
);
is( $type1_no1->in_type1, 'this property belongs to Type1',
    'type1 no1 in_type1',
);

ok(! $type1_no1->can('in_type2'), 'type1 no1 cannot in_type2');

my $type1_no2 = TestComplete->new({
    type => 'Type1',
    from_base => 'this property lives in base instance 2',
    in_type1  => 'this property belongs to Type1 instance 2',
});
isa_ok($type1_no2, 'TestComplete::Type1');

is( $type1_no2->from_base, 'this property lives in base instance 2',
    'type1 no2 from_base',
);
is( $type1_no2->in_type1, 'this property belongs to Type1 instance 2',
    'type1 no2 in_type1',
);
 
ok(! $type1_no2->can('in_type2'), 'type1 no2 cannot in_type2');

# ### TestComplete::Type2
my $type2_no1 = TestComplete->new({
    type => 'Type2',
    from_base => 'this property lives in base',
    in_type2  => 'this property belongs to Type2',
});
isa_ok($type2_no1, 'TestComplete::Type2');

is( $type2_no1->from_base, 'this property lives in base',
    'type2 no1 from_base',
);
is( $type2_no1->in_type2, 'this property belongs to Type2',
    'type2 no1 in_type2',
);

ok(! $type2_no1->can('in_type1'), 'type2 no1 cannot in_type1');

my $type2_no2 = TestComplete->new({
    type => 'Type2',
    from_base => 'this property lives in base instance 2',
    in_type2  => 'this property belongs to Type2 instance 2',
});
isa_ok($type2_no2, 'TestComplete::Type2');

is( $type2_no2->from_base, 'this property lives in base instance 2',
    'type2 no2 from_base',
);
is( $type2_no2->in_type2, 'this property belongs to Type2 instance 2',
    'type2 no2 in_type2',
);

ok(! $type2_no2->can('in_type1'), 'type2 no2 cannot in_type1');

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
