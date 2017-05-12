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
	   10 => '',
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
	   c => 3,
	   e => {
		 e1 => {
		       },
		 e2 => {
			1 => 2,
			3 => 4,
		       },
		},
	  };

    my $source
	= {
           a => 1,
	   b => 2,
	   e => {
		 e1 => [
			0,
			1,
		       ],
		 e2 => {
			5 => 6,
		       },
		 e3 => [
		       ],
		},
	  };

    my $expected_data
	= {
           a => 1,
	   b => 2,
	   c => 3,
	   e => {
		 e1 => [
			0,
			1,
		       ],
		 e2 => {
			1 => 2,
			3 => 4,
			5 => 6,
		       },
		 e3 => [
		       ],
		},
	  };

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'simultaneous merge at different levels');
}


if (!$disabled_tests->{2})
{
    my $target
	= [
           0,
	   1,
	  ];

    my $source
	= [
	   undef,
	   undef,
	   undef,
	   3,
	  ];

    my $expected_data
	= [
           0,
	   1,
	   undef,
	   3,
	  ];

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array merge keeps undef values');
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
	   undef,
	   undef,
	  ];

    my $expected_data
	= [
           1,
	   {},
	  ];

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array undef entries in source do not overwrite in the target');
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
	   undef,
	   [],
	  ];

    my $expected_data
	= [
           1,
	   [],
	  ];

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array undef entries in source do not stop a merging loop, next entries overwrite');
}


if (!$disabled_tests->{5})
{
    my $target
	= [
           0,
	   1,
	  ];

    my $source
	= [
	   undef,
	   undef,
	   undef,
	   3,
	  ];

    my $expected_data
	= [
           undef,
	   undef,
	   undef,
	   3,
	  ];

    my $merged_data = merger($target, $source, { undefined => { overwrites => 1, }, }, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array merge overwrites undef values on request');
}


if (!$disabled_tests->{6})
{
    my $target
	= [
           1,
	   {},
	  ];

    my $source
	= [
	   undef,
	   undef,
	  ];

    my $expected_data
	= [
           undef,
	   undef,
	  ];

    my $merged_data = merger($target, $source, { undefined => { overwrites => 1, }, }, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array undef entries in source do overwrite in the target on request');
}


if (!$disabled_tests->{7})
{
    my $target
	= [
           1,
	   {},
	  ];

    my $source
	= [
	   undef,
	   [],
	  ];

    my $expected_data
	= [
           undef,
	   [],
	  ];

    my $merged_data = merger($target, $source, { undefined => { overwrites => 1, }, }, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'array undef entries in source do not stop a merging loop, next entries overwrite');
}


if (!$disabled_tests->{8})
{
    my $target
	= {
           1 => undef,
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

    ok($differences->is_empty(), 'hash undef in target gets overwritten');
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
	   1 => undef,
	   3 => [],
	  };

    my $expected_data
	= {
           1 => 2,
	   3 => [],
	  };

    my $merged_data = merger($target, $source, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'hashes undef in source, does not overwrite');
}


if (!$disabled_tests->{10})
{
    my $target
	= {
           1 => 2,
	   3 => {},
	  };

    my $source
	= {
	   1 => undef,
	   3 => [],
	  };

    my $expected_data
	= {
           1 => undef,
	   3 => [],
	  };

    my $merged_data = merger($target, $source, { undefined => { overwrites => 1, }, }, );

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    use Data::Dumper;

    print Dumper($merged_data);

    ok($differences->is_empty(), 'hashes undef in source, does not overwrite');
}


