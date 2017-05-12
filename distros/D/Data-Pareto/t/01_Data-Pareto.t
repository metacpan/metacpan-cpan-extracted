use Test::More tests => 49;

# TODO: is it OK to garbage users' screen?
#use Carp;
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Data::Pareto;

diag( "Testing Data::Pareto $Data::Pareto::VERSION, Perl $], $^X" );

# a helper method to calculate Pareto set from given vectors
sub _p_obj {
	my $num = shift;
	my $opts = { };
	$opts = shift if @_ && ref($_[0]) eq 'HASH';
	my $p = Data::Pareto->new({ columns => [ 0..$num-1 ], %$opts });
	$p->add(@_) if @_;
	return $p
}
sub _p {
	_p_obj(@_)->get_pareto_ref();
}

# same as above, assuming duplicates are allowed
sub _p_dup {
	my $num = shift;
	my $opts = { };
	$opts = shift if @_ && ref($_[0]) eq 'HASH';
	return _p($num, { duplicates => 1, %$opts }, @_);
}

##### different subs behaviour depending on params
{
	## invalid values
	my $p = _p_obj(1);
	ok( ! $p->is_invalid(0));
	ok( ! $p->is_invalid('?'));
	
	$p = _p_obj(1, { invalid => '?' }, [1]);
	ok( $p->is_invalid('?'));
	ok( ! $p->is_invalid(0));
	ok( ! $p->is_invalid('!'));
	ok( ! $p->is_invalid('?!'));
	
	## domination subs
	$p = _p_obj(2);
	ok( $p->is_dominated([1, 3], [1, 2]));
	ok( !$p->is_dominated([1, 2], [1, 3]));
	ok( $p->is_dominated([3, 1], [2, 1]));
	ok( !$p->is_dominated([2, 1], [3, 1]));

	## custom domination subs -- lexicographic one
	my $lexi_dominator = sub {
		my ($col, $dominated, $by) = @_;
		return ($dominated ge $by);
	};
	$p = _p_obj(2, { column_dominator =>  $lexi_dominator });
	ok( $p->is_dominated(['b', 2], ['a', 2]));
	ok( ! $p->is_dominated(['a', 2], ['b', 2]));
	ok( $p->is_dominated(['a', 3], ['a', 2]));
	ok( ! $p->is_dominated(['a', 2], ['a', 3]));
	ok( ! $p->is_dominated(['a', 3], ['b', 2]));
	ok( ! $p->is_dominated(['b', 2], ['a', 3]));
	
	ok( $p->is_dominated(['a', 2], ['a', 12]));	# numbers are ALSO compared as strings!
	ok( ! $p->is_dominated(['a', 12], ['a', 2]));
	
	## custom domination subs -- many of them
	$p = _p_obj(2, { column_dominator => {
		0 => $lexi_dominator,
		1 => sub {
			my ($col, $dominated, $by) = @_;
			return ($dominated >= $by);
		}
	}});
	ok( ! $p->is_dominated(['a', 2], ['a', 12]));	# now numbers are compared as numbers
	ok( $p->is_dominated(['a', 12], ['a', 2]));
	
	## custom domination subs -- builtin
	ok( _p_obj(2, { column_dominator => 'min' })->is_dominated([1, 3], [1, 2]) );
	ok( ! _p_obj(2, { column_dominator => 'min' })->is_dominated([1, 2], [1, 3]) );
	ok( _p_obj(2, { column_dominator => 'max' })->is_dominated([1, 2], [1, 3]) );
	ok( ! _p_obj(2, { column_dominator => 'max' })->is_dominated([1, 3], [1, 2]) );
	ok( _p_obj(2, { column_dominator => 'lexi' })->is_dominated(['ewa', 'ja'], ['ela', 'ja']) );
	ok( ! _p_obj(2, { column_dominator => 'lexi' })->is_dominated(['ela', 'ja'], ['ewa', 'ja']) );
	ok( _p_obj(2, { column_dominator => 'lexi_rev' })->is_dominated(['ela', 'ja'], ['ewa', 'ja']) );
	ok( ! _p_obj(2, { column_dominator => 'lexi_rev' })->is_dominated(['ewa', 'ja'], ['ela', 'ja']) );
	SKIP: {
		my $test_exception_exception;
		BEGIN {
			eval { require Test::Exception; Test::Exception->import; };
			$test_exception_exception = $@;
		}
		skip 'Test::Exception is not installed', 2 if $test_exception_exception;
		throws_ok { _p_obj(1, { column_dominator => 'blabla' }) } qr/unrecognized.*builtin/i, 'died correctly';
		throws_ok { _p_obj(1, { column_dominator => undef }) } qr/unrecognized.*builtin/i, 'died correctly';
	}
}


##### call context tests
{
	# list context
	my @arr = _p_obj(2, [1,2], [2,1])->get_pareto();
	my $arr = _p_obj(2, [1,2], [2,1])->get_pareto();
	is_deeply(
		\@arr,
		[ [1,2], [2,1] ]
	);
	is($arr, 2);
	
	# scalar context
	my   $scl = _p_obj(2, [1,2], [2,1])->get_pareto_ref();
	my (@scl) = _p_obj(2, [1,2], [2,1])->get_pareto_ref();
	is_deeply(
		$scl,
		[ [1,2], [2,1] ]
	);
	is_deeply(
		\@scl,
		[
			[ [1,2], [2,1] ]
		]
	);
	
}

##### simple, <1 element sets

is_deeply (
	_p(2),
	[ ]
);

is_deeply (
	_p(2, [1,2]),
	[ [1,2] ]
);

is_deeply (
	_p(2, [1,2], [1,2]),
	[ [1,2] ]
);

is_deeply (
	_p_dup(2, [1,2], [1,2]),
	[ [1,2], [1,2] ]
);

##### simple, 2 element sets of different column values

is_deeply (
	_p(2, [1,2], [1,3]),
	[ [1,2] ]
);

is_deeply (
	_p(2, [1,2], [2,2]),
	[ [1,2] ]
);

is_deeply (
	_p(2, [1,3], [1,2]),
	[ [1,2] ]
);

is_deeply (
	_p(2, [2,2], [1,2]),
	[ [1,2] ]
);

##### adding element, removing element, tried to add again; in different confs.

is_deeply (
	_p(2, [2,2], [1,2], [2,2]),
	[ [1, 2] ]
);

is_deeply (
	_p_dup(2, [2,2], [2,2], [1,2]),
	[ [1,2] ]
);

is_deeply (
	_p_dup(2, [1,2], [2,2], [1,2], [2,2]),
	[ [1,2], [1,2] ]
);

##### many pareto vectors

is_deeply (
	_p(3, [1,2,9], [2,2,8], [3,3,7], [4,3,6], [5,7,5]),
	[ [1,2,9], [2,2,8], [3,3,7], [4,3,6], [5,7,5] ]
);

##### invalid values

is_deeply (
	_p(3, {invalid => '?'}, [1,'?',2], [0,1,2]),
	[ [0,1,2] ]
);

is_deeply (
	_p(3, {invalid => '?'}, [0,'?',2], [1,1,2]),
	[ [0,'?',2], [1,1,2] ]
);

is_deeply (
	_p(4, {invalid => '?'}, [0,'?',2,2], [1,1,'?',2]),
	[ [0,'?',2,2], [1,1,'?',2] ]
);

