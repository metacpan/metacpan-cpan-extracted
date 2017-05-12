#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb
#


use strict;


our $disabled_tests;

BEGIN
{
    $disabled_tests
	= {
	   1 => '',
	   2 => '',
	   3 => '',
	   4 => '',
	   5 => '',
	   6 => '',
	   7 => '',
	   8 => '',
	   9 => '',
	  };
}


use Test::More tests => (scalar ( grep { print "$_\n" ; !$_ } values %$disabled_tests ) );

use Data::Comparator qw(data_comparator);
use Data::Transformator;


if (!$disabled_tests->{1})
{
    my $hash1
	= {
	   1 => 'a',
	   2 => 'b',
	  };

    my $result = data_comparator($hash1, $hash1);

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 1: success\n";

	ok(1, '1: success');
    }
    else
    {
	print "$0: 1: failed\n";

	ok(0, '1: failed');
    }
}


if (!$disabled_tests->{2})
{
    my $hash1
	= {
	   1 => 'a',
	   2 => 'b',
	  };

    my $hash2
	= {
	   1 => 'a',
	   3 => 'b',
	  };

    my $differences
	= bless(
		{
		 '3' => bless( do{ \ (my $o = 'b')}, 'Data::Differences' )
		},
		'Data::Differences'
	       );

    my $result = data_comparator($hash1, $hash2, $differences, );

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 2: success\n";

	ok(1, '2: success');
    }
    else
    {
	print "$0: 2: failed\n";

	ok(0, '2: failed');
    }
}


if (!$disabled_tests->{3})
{
    my $array1
	= [
	   'a',
	   'b',
	  ];

    my $result = data_comparator($array1, $array1);

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 3: success\n";

	ok(1, '3: success');
    }
    else
    {
	print "$0: 3: failed\n";

	ok(0, '3: failed');
    }
}


if (!$disabled_tests->{4})
{
    my $array1
	= [
	   'a',
	   'b',
	  ];

    my $array2
	= [
	   'a',
	   'cb',
	  ];

    my $old_but_wrong_I_guess
	= bless(
		[
		 \undef,
		 bless( do{ \ (my $o = 'cb') }, 'Data::Differences' )
		],
		'Data::Differences'
	       );

    my $differences
	= bless(
		[
                 undef,
                 bless( do{ \ (my $o = 'cb') }, 'Data::Differences' )
		],
		'Data::Differences'
	       );

    my $result = data_comparator($array1, $array2, $differences, );

    use Data::Dumper;

    print Dumper($result);

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 4: success\n";

	ok(1, '4: success');
    }
    else
    {
	print "$0: 4: failed\n";

	ok(0, '4: failed');
    }
}


if (!$disabled_tests->{5})
{
    my $differences1
	= bless( {
		  'site_full_name' => bless( do{ \ (my $o = 'HCO at your service')}, 'Data::Differences' ),
		 'license' => bless( do{ \ (my $o = '3b0f:4044:a7d3:6994:c1b5:f6fe:6a61:a09c')}, 'Data::Differences' )
		 }, 'Data::Differences' );
    my $differences2
	= bless( {
		  'license' => bless( do{ \ (my $o = '3b0f:4044:a7d3:6994:c1b5:f6fe:6a61:a09c')}, 'Data::Differences' ),
		  'site_full_name' => bless( do{ \ (my $o = 'HCO at your service')}, 'Data::Differences' )
		 }, 'Data::Differences' );

    my $differences
	= bless(
		[
                 \undef,
                 bless( do{ \ (my $o = 'cb') }, 'Data::Differences' )
		],
		'Data::Differences'
	       );

    my $result = data_comparator($differences1, $differences2, );

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 5: success\n";

	ok(1, '5: success');
    }
    else
    {
	print "$0: 5: failed\n";

	ok(0, '5: failed');
    }
}


if (!$disabled_tests->{6})
{
    my $sems_config1
	= {
	   'site_full_name' => 'HCO at your service',
	   'license' => '3b0f:4044:a7d3:6994:c1b5:f6fe:6a61:a09c',
	   'devices' => {
			 MOD_1 => {
				   addr => 2,
				   type => 'ntc2180qtel',
				  },
			},
	  };
    my $sems_config2
	= {
	   'site_full_name' => 'HCO at your service',
	   'license' => '3b0f:4044:a7d3:6994:c1b5:f6fe:6a61:a09c',
	   'devices' => {
			 MOD_1 => {
				   addr => 2,
				   type => 'ntc2180',
				  },
			},
	  };

    my $differences
	= bless(
		{
                 'devices' => bless( {
				      'MOD_1' => bless( {
							 'type' => bless( do{ \ (my $o = 'ntc2180')}, 'Data::Differences' )
						   }, 'Data::Differences' )
				}, 'Data::Differences' )
	    }, 'Data::Differences' );

    my $result = data_comparator($sems_config1, $sems_config2, $differences, );

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 6: success\n";

	ok(1, '6: success');
    }
    else
    {
	print "$0: 6: failed\n";

	ok(0, '6: failed');
    }
}


if (!$disabled_tests->{7})
{
    my $nested_array1
	= [
	   [
	    [ 'a', 'b', ],
	    [ '1', '2', ],
	   ],
	   [
	    [ 'a', 'b', ],
	    [ '1', '2', ],
	   ],
	  ];
    my $nested_array2
	= [
	   [
	    [ 'a', 'b', ],
	    [ '1', '2', ],
	   ],
	   [
	    [ 'a', 'b', ],
	    [ '1', '3', ],
	   ],
	  ];

    my $differences
	= bless(
		[
                 undef,
                 bless( [
			 undef,
			 bless( [
				 undef,
				 bless( do{\(my $o = '3')}, 'Data::Differences' )
			      ], 'Data::Differences' )
		      ], 'Data::Differences' )
               ], 'Data::Differences' );

    my $result = data_comparator($nested_array1, $nested_array2, $differences, );

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 7: success\n";

	ok(1, '7: success');
    }
    else
    {
	print "$0: 7: failed\n";

	ok(0, '7: failed');
    }
}


if (!$disabled_tests->{8})
{
    my $nested_array1
	= [
	   [
	    [ 'a', 'b', ],
	    [ '1', '2', ],
	   ],
	  ];
    my $nested_array2
	= [
	   [
	    [ 'a', 'b', ],
	    [ '1', '2', ],
	   ],
	   [
	    [ 'a', 'b', ],
	    [ '1', '2', ],
	   ],
	  ];

    my $differences
	= bless( [
		  undef,
		  bless( do{ \ (my $o = [
					 [
					  'a',
					  'b'
					 ],
					 [
					  '1',
					  '2'
					 ]
					])}, 'Data::Differences' )
		 ], 'Data::Differences' );

    my $result = data_comparator($nested_array1, $nested_array2, $differences, );

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 8: success\n";

	ok(1, '8: success');
    }
    else
    {
	print "$0: 8: failed\n";

	ok(0, '8: failed');
    }
}


if (!$disabled_tests->{9})
{
    my $sems_config1
	= {
	   'site_full_name' => 'HCO at your service',
	   'license' => '3b0f:4044:a7d3:6994:c1b5:f6fe:6a61:a09c',
	  };
    my $sems_config2
	= {
	   'site_full_name' => 'HCO at your service',
	   'license' => '3b0f:4044:a7d3:6994:c1b5:f6fe:6a61:a09c',
	   'devices' => {
			 MOD_1 => {
				   addr => 2,
				   type => 'ntc2180',
				  },
			},
	  };

    my $differences
	= bless( {
		  'devices' => bless( do{ \ (my $o = {
						      'MOD_1' => {
								  'type' => 'ntc2180',
								  'addr' => 2
								 }
						     })}, 'Data::Differences' )
		 }, 'Data::Differences' );

    my $result = data_comparator($sems_config1, $sems_config2, $differences, );

    $result = $result->is_empty();

    if ($result)
    {
	print "$0: 9: success\n";

	ok(1, '9: success');
    }
    else
    {
	print "$0: 9: failed\n";

	ok(0, '9: failed');
    }
}


