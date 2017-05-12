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


use Test::More tests => (scalar ( grep { !$_ } values %$disabled_tests ) );

use Data::Comparator qw(data_comparator);
use Data::Merger qw(merger);


if (!$disabled_tests->{1})
{
    my $target
	= {
           a => 2,
	   e => {
		 e1 => {
		       },
		},
	  };

    my $source
	= {
           a => 1,
	   e => {
		 e2 => {
		       },
		 e3 => {
		       },
		},
	  };

    my $expected_data
	= {
           a => 1,
	   e => {
		 e1 => {
		       },
		 e2 => {
		       },
		 e3 => {
		       },
		},
	  };

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'simple merge');
}


if (!$disabled_tests->{2})
{
    my $target
	= [
           1,
	   1,
	  ];

    my $source
	= [
	   0,
	  ];

    my $expected_data
	= [
           0,
	   1,
	  ];

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array merge');
}


if (!$disabled_tests->{3})
{
    my $target
	= [
           1,
	   {},
	  ];

    my $source
	= [
	   0,
	  ];

    my $expected_data
	= [
           0,
	   {},
	  ];

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'one array larger, hash entry');
}


if (!$disabled_tests->{4})
{
    my $target
	= [
           1,
	   {},
	  ];

    my $source
	= [
	   0,
	   [],
	  ];

    my $expected_data
	= [
           0,
	   [],
	  ];

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array different types, overwrites');
}


if (!$disabled_tests->{5})
{
    my $target
	= [
           1,
	   {},
	  ];

    my $source
	= [
	   0,
	   [],
	  ];

    my $expected_data
	= [
           0,
	   {},
	  ];

    my $merged_data = merger($target, $source, { arrays => { overwrite => 0, }, }, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array different types, option not to overwrite');
}


if (!$disabled_tests->{6})
{
    my $target
	= {
           1 => 2,
	   3 => 4,
	  };

    my $source
	= {
	   1 => 1,
	  };

    my $expected_data
	= {
           1 => 1,
	   3 => 4,
	  };

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'hash merge');
}


if (!$disabled_tests->{7})
{
    my $target
	= {
           1 => 2,
	   3 => {},
	  };

    my $source
	= {
	   1 => 1,
	  };

    my $expected_data
	= {
           1 => 1,
	   3 => {},
	  };

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'one hash larger, hash value');
}


if (!$disabled_tests->{8})
{
    my $target
	= {
           1 => 2,
	   3 => {},
	  };

    my $source
	= {
	   1 => 1,
	   3 => [],
	  };

    my $expected_data
	= {
           1 => 1,
	   3 => [],
	  };

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'hash different types, overwrites');
}


if (!$disabled_tests->{9})
{
    my $target
	= {
           1 => 2,
	   3 => {},
	  };

    my $source
	= {
	   1 => 1,
	   3 => [],
	  };

    my $expected_data
	= {
           1 => 1,
	   3 => {},
	  };

    my $merged_data = merger($target, $source, { hashes => { overwrite => 0, }, }, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'hashes different types, option not to overwrite');
}


