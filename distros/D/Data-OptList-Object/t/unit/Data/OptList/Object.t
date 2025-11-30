=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::OptList::Object>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test2::V0 -target => 'Data::OptList::Object';
use Test2::Tools::Spec;
use Data::Dumper;

sub new_ok {
	&isa_ok( @_ );
	return $_[0];
}

describe "class `$CLASS`" => sub {

	tests 'constructor' => sub {

		my $o1 = new_ok $CLASS->new( qw/ foo bar / ), [$CLASS], 'intantiated with list';
		is( [ $o1->KEYS ], [ qw/ foo bar / ] );

		my $o2 = new_ok $CLASS->new( [ qw/ foo bar / ] ), [$CLASS], 'intantiated with arrayref';
		is( [ $o2->KEYS ], [ qw/ foo bar / ] );

		my $o3 = new_ok $CLASS->new( { foo => undef, bar => undef } ), [$CLASS], 'intantiated with hashref';
		is( [ $o3->KEYS ], [ qw/ bar foo / ] );  # always sorted

		my $o4 = new_ok $CLASS->new( $o1 ), [$CLASS], 'intantiated with object';
		is( [ $o4->KEYS ], [ qw/ foo bar / ] );
	};

	tests 'method `ALL`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		is( scalar($o->ALL), 3, 'scalar context' );

		my @all = $o->ALL;
		is( scalar(@all), 3, 'list context' );
		is( $all[0]->key, 'foo', '... first key' );
		is( $all[0]->value, undef, '... first value' );
		is( $all[1]->key, 'bar', '... second key' );
		is( $all[1]->value, undef, '... second value' );
		is( $all[2]->key, 'foo', '... third key' );
		is( $all[2]->value, {}, '... third value' );
	};

	tests 'method `COUNT`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( scalar($o->COUNT), 3, 'scalar context' );
		is( [$o->COUNT], [3], 'list context' );
	};

	tests 'method `KEYS`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( [ $o->KEYS ], [ qw/ foo bar foo / ], 'list context' );
	};

	tests 'method `VALUES`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( [ $o->VALUES ], [ undef, undef, {} ], 'list context' );
	};
	
	tests 'method `TO_LIST`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( [ $o->TO_LIST ], [ qw/ foo bar foo /, {} ], 'simple case' );

		$o = new_ok $CLASS->new( quux => undef, qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( [ $o->TO_LIST ], [ qw/ quux foo bar foo /, {} ], 'canonicalized case' );
	};

	tests 'method `TO_ARRAYREF`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		my $all = $o->TO_ARRAYREF;
		is( scalar(@$all), 3, 'list context' );
		is( $all->[0]->key, 'foo', '... first key' );
		is( $all->[0]->value, undef, '... first value' );
		is( $all->[1]->key, 'bar', '... second key' );
		is( $all->[1]->value, undef, '... second value' );
		is( $all->[2]->key, 'foo', '... third key' );
		is( $all->[2]->value, {}, '... third value' );
	};

	tests 'method `TO_JSON`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( $o->TO_JSON, [ qw/ foo bar foo /, {} ], 'simple case' );

		$o = new_ok $CLASS->new( quux => undef, qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( $o->TO_JSON, [ qw/ quux foo bar foo /, {} ], 'canonicalized case' );
	};

	tests 'method `TO_HASHREF`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		my $href = $o->TO_HASHREF;
		is( scalar(keys %$href), 2, 'correct keys' );
		is( $href->{foo}, {}, '... key "foo"' );
		is( $href->{bar}, undef, '... key "bar"' );
		my $e = dies { $href->{baz} = 999 };
		like $e, qr/disallowed key/, 'hashref is read only';
	};

	tests 'method `TO_REGEXP`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		my $re = $o->TO_REGEXP;
		ok( re::is_regexp($re), 'made a regexp' );
		ok( 'foo'  =~ $re, 'matches "foo"' );
		ok( 'bar'  =~ $re, 'matches "bar"' );
		ok( 'FOO'  !~ $re, 'not matches "FOO"' );
		ok( 'fool' !~ $re, 'not matches "fool"' );
	};

	tests 'method `GET`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		my $PAIR    = "$CLASS\::_Pair";
		my $NOVALUE = "$CLASS\::_NoValue";

		is(
			[ $o->GET('foo') ],
			[ bless([ foo => undef ], $PAIR), bless([ foo => {} ], $PAIR) ],
			'GET(Str) in list context',
		);

		is(
			[ $o->GET(qr/f/) ],
			[ bless([ foo => undef ], $PAIR), bless([ foo => {} ], $PAIR) ],
			'GET(RegexpRef) in list context',
		);

		is(
			[ $o->GET(sub { $_->key eq 'foo' }) ],
			[ bless([ foo => undef ], $PAIR), bless([ foo => {} ], $PAIR) ],
			'GET(CodeRef) in list context',
		);

		is(
			[ $o->GET('not_exists') ],
			[],
			'GET("not_exists") in list context',
		);

		is(
			scalar( $o->GET('foo') ),
			bless([ foo => undef ], $PAIR),
			'GET(Str) in scalar context',
		);

		is(
			scalar( $o->GET(qr/f/) ),
			bless([ foo => undef ], $PAIR),
			'GET(RegexpRef) in scalar context',
		);

		is(
			scalar( $o->GET(sub { $_->key eq 'foo' }) ),
			bless([ foo => undef ], $PAIR),
			'GET(CodeRef) in scalar context',
		);

		is(
			scalar( $o->GET('not_exists') ),
			bless([ 'not_exists' ], $NOVALUE),
			'GET("not_exists") in scalar context',
		);
	};

	tests 'method `HAS`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		ok(
			$o->HAS('foo'),
			'HAS(Str)',
		);

		ok(
			$o->HAS(qr/f/),
			'HAS(RegexpRef)',
		);

		ok(
			$o->HAS(sub { $_->key eq 'foo' }),
			'HAS(CodeRef)',
		);

		ok(
			!$o->HAS('not_exists'),
			'HAS("not_exists")',
		);
	};

	tests 'method `AUTOLOAD`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		my $PAIR    = "$CLASS\::_Pair";
		my $NOVALUE = "$CLASS\::_NoValue";

		is(
			[ $o->foo ],
			[ bless([ foo => undef ], $PAIR), bless([ foo => {} ], $PAIR) ],
			'foo in list context',
		);

		is(
			[ $o->not_exists ],
			[],
			'not_exists in list context',
		);

		is(
			scalar( $o->foo ),
			bless([ foo => undef ], $PAIR),
			'foo in scalar context',
		);

		is(
			scalar( $o->not_exists ),
			bless([ 'not_exists' ], $NOVALUE),
			'not_exists in scalar context',
		);
	};

	tests 'method `MATCH`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		ok(
			$o->MATCH('foo'),
			'MATCH(Str)',
		);

		ok(
			$o->MATCH(qr/f/),
			'MATCH(RegexpRef)',
		);

		ok(
			$o->MATCH(sub { $_->key eq 'foo' }),
			'MATCH(CodeRef)',
		);

		ok(
			!$o->MATCH('not_exists'),
			'MATCH("not_exists")',
		);
	};

	tests 'overload `bool`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		ok( !!$o, 'non-empty optlist is true' );

		$o = new_ok $CLASS->new, [$CLASS], 'made object';
		ok( !!$o, 'empty optlist is still true' );
	};

	tests 'overload `""`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( "$o", "OptList(foo bar foo)", 'non-empty optlist stringifies correctly' );

		$o = new_ok $CLASS->new, [$CLASS], 'made object';
		is( "$o", "OptList()", 'empty optlist stringifies correctly' );
	};

	tests 'overload `0+`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';
		is( 0+$o, 3, 'non-empty optlist numifies correctly' );

		$o = new_ok $CLASS->new, [$CLASS], 'made object';
		is( 0+$o, 0, 'empty optlist numifies correctly' );
	};

	tests 'overload `@{}`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		is( scalar(@$o), 3, 'correct length array' );
		is( $o->[0]->key, 'foo', '... first key' );
		is( $o->[0]->value, undef, '... first value' );
		is( $o->[1]->key, 'bar', '... second key' );
		is( $o->[1]->value, undef, '... second value' );
		is( $o->[2]->key, 'foo', '... third key' );
		is( $o->[2]->value, {}, '... third value' );
	};

	tests 'overload `%{}`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		is( scalar(keys %$o), 2, 'correct keys' );
		is( $o->{foo}, {}, '... key "foo"' );
		is( $o->{bar}, undef, '... key "bar"' );
		my $e = dies { $o->{baz} = 999 };
		like $e, qr/disallowed key/, 'hashref is read only';
	};

	tests 'overload `qr`' => sub {
		my $o = new_ok $CLASS->new( qw/ foo bar foo /, {} ), [$CLASS], 'made object';

		ok( 'foo'  =~ $o, 'matches "foo"' );
		ok( 'bar'  =~ $o, 'matches "bar"' );
		ok( 'FOO'  !~ $o, 'not matches "FOO"' );
		ok( 'fool' !~ $o, 'not matches "fool"' );
	};
};

done_testing;
