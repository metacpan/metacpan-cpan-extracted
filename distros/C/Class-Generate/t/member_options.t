#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test options associated with members:
#   --	Default.
#   --	Type.
#   --	Required.
#   --	Readonly.
#   --	Private.

use Class::Generate qw(&class);

use vars qw($o);

Test
{
    class Default => [ mem => "\$" ];
    ( Default->new( mem => 1 ) )->mem == 1 && !defined( ( Default->new )->mem );
};

Test
{
    class Type_Explicit => [ mem => { type => "\$" } ];
    ( Type_Explicit->new( mem => 1 ) )->mem == 1
        && !defined( ( Default->new )->mem );
};

Test
{
    class Mem_Required => [ mem => { type => "\$", required => 1 } ];
    Mem_Required->new( mem => 1 )->mem == 1;
};
Test_Failure { Mem_Required->new };
Test_Failure { class Missing_Type => [ mem => { required => 1 } ] };

Test
{
    class Readonly_Mems => [
        m1 => { type => "\$", readonly => 1 },
        m2 => { type => '@',  readonly => 1 },
        m3 => { type => '%',  readonly => 1 }
    ];
    $o = new Readonly_Mems( m1 => 1, m2 => [2], m3 => { v => 3 } );
    (          $o->m1 == 1
            && $o->m2_size == 0
            && $o->m2(0) == 2
            && $o->last_m2 == 2
            && $o->m3('v') == 3 )
};

Test_Failure { $o->add_m2( 3, 4, 5 ) };
Test_Failure { $o->undef_m1 };
Test_Failure { $o->undef_m2 };
Test_Failure { $o->undef_m3 };
Test_Failure { $o->m1(2) };
Test_Failure { $o->m2( 0, 1 ) };
Test_Failure { $o->m3( 'v', 1 ) };
Test_Failure { $o->m2( [1] ) };
Test_Failure { $o->m3( { v => 4 } ) };

Test
{
    class Private_Mem => [ mem => { type => "\$", private => 1 } ];
    1;
};

Test_Failure { new Private_Mem( mem => 1 ) };
Test_Failure { Private_Mem->new()->mem };

Test
{
    class Private_Mem_Accessors => {
        smem      => { type => "\$", private => 1 },
        amem      => { type => "@",  private => 1 },
        hmem      => { type => "%",  private => 1 },
        '&method' => q{
	    $smem = 1; &undef_smem;
	    @amem = (1, 2, 3); &add_amem(&amem_size, &last_amem); &undef_amem;
	    %hmem = ( v => 1 ); @amem = &hmem_keys; @amem = &hmem_values;
	    &delete_hmem('v'); &undef_hmem;},
        '&get_values' => q{ return ((defined $smem ? $smem : 0),
				    (&amem_size >= 0 ? @amem : ()),
				    (&hmem_keys ? %hmem : ())); }
    };
    $o = new Private_Mem_Accessors;
    $o->method;
    Arrays_Equal( [ $o->get_values ], [ 0, 1 ] )
};

Report_Results;
