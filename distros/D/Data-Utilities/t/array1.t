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
	  };
}


use Test::More tests => (scalar ( grep { print "$_\n" ; !$_ } values %$disabled_tests ) );

use Data::Comparator qw(data_comparator);
use Data::Transformator;


if (!$disabled_tests->{1})
{
    my $tree
	= [
	   1,
	   2,
	   3,
	   4,
	  ];

    my $expected_data
	= [
	   1,
	   2,
	   3,
	   4,
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform_array1',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
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
    my $tree
	= [
	   [],
	   [],
	  ];

    my $expected_data
	= [
	   [],
	   [],
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform_array2',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
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
    my $tree
	= [
	   {},
	   {},
	  ];

    my $expected_data
	= [
	   {},
	   {},
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform_array3',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
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
    my $tree
	= [
	   [ 1, 2, 3, 4, ],
	   [ 5, 6, 7, 8, ],
	  ];

    my $expected_data
	= [
	   [ 1, 2, 3, 4, ],
	   [ 5, 6, 7, 8, ],
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform_array4',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
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
    my $tree
	= [
	   { 1 => 2, 3 => 4, },
	   { 5 => 6, 7 => 8, },
	  ];

    my $expected_data
	= [
	   { 1 => 2, 3 => 4, },
	   { 5 => 6, 7 => 8, },
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform_array5',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
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
    my $tree
	= [
	   [
	    '-b1',
	    '-b2',
	    '-b3',
	   ],
	  ];

    my $expected_data
	= [
	   {
            '1' => '-b2',
            '0' => '-b1',
            '2' => '-b3'
	   }
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     contents => $tree,
	     name => 'test_transform_array6',
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_array_to_hash('[0]', '->[0]'),
	     ],
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
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


