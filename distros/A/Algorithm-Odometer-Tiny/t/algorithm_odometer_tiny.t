#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl distribution Algorithm-Odometer-Tiny.

=head1 Author, Copyright, and License

Copyright (c) 2019 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Algorithm_Odometer_Tiny_Testlib;
use List::Util qw/reduce/;

use constant TESTCOUNT => 16; ## no critic (ProhibitConstantPragma)
use Test::More tests => TESTCOUNT;

BEGIN {
	diag "This is Perl $] at $^X on $^O";
	use_ok('Algorithm::Odometer::Tiny') or BAIL_OUT("failed to use Algorithm::Odometer::Tiny");
	use_ok('Algorithm::Odometer::Gray') or BAIL_OUT("failed to use Algorithm::Odometer::Gray");
}
is $Algorithm::Odometer::Tiny::VERSION, '0.02', 'Algorithm::Odometer::Tiny version matches tests';
is $Algorithm::Odometer::Gray::VERSION, '0.02', 'Algorithm::Odometer::Gray version matches tests';

{
	my $odo = Algorithm::Odometer::Tiny->new( ['foo','bar'], '-', [3..5] );
	my @o;
	while (<$odo>) { push @o, $_ }
	while (my @c = $odo->()) { push @o, \@c } # re-start odometer
	is_deeply \@o, ["foo-3", "foo-4", "foo-5", "bar-3", "bar-4", "bar-5",
		["foo","-","3"], ["foo","-","4"], ["foo","-","5"], ["bar","-","3"], ["bar","-","4"], ["bar","-","5"] ],
		'basic test 1/2';
}
subtest 'basic tests 2/2' => sub {  ## no critic (RequireTestLabels)
	plan tests=>28;
	my $odo1 = new_ok('Algorithm::Odometer::Tiny' => [ [qw/a b c/], [qw/1 2/] ]);
	is $odo1->(), 'a1';
	is $odo1->(), 'a2';
	is <$odo1>, 'b1';
	is_deeply [$odo1->()], ['b','2'];
	is $odo1->(), 'c1';
	is_deeply [$odo1->()], ['c','2'];
	is $odo1->(), undef;
	is $odo1->(), 'a1';
	my $odo2 = new_ok('Algorithm::Odometer::Tiny' => [ 'r', [qw/X Y/], [qw/9 0/], [qw/- _/] ]);
	is $odo2->(), 'rX9-';
	is $odo2->(), 'rX9_';
	is <$odo2>, 'rX0-';
	is <$odo2>, 'rX0_';
	is <$odo2>, 'rY9-';
	is_deeply [$odo2->()], ['r','Y','9','_'];
	is_deeply [$odo2->()], ['r','Y','0','-'];
	is $odo2->(), 'rY0_';
	is_deeply [$odo2->()], [];
	is $odo2->(), 'rX9-';
	my $odo3 = new_ok('Algorithm::Odometer::Tiny' => [ [0..9],[0..9],[0..9] ]);
	my @res;
	push @res, $_ while <$odo3>;
	is_deeply \@res, [map {sprintf '%03d', $_} 0..999];
	my $odo4 = new_ok('Algorithm::Odometer::Tiny' => [ [qw/a b/], [undef, {x=>3}] ]);
	is <$odo4>, 'a';
	like <$odo4>, qr/^aHASH\(0x[a-fA-F0-9]+\)$/;
	is_deeply [$odo4->()], ['b', undef];
	is_deeply [$odo4->()], ['b', {x=>3}];
	is <$odo4>, undef;
};

{
	my $odo = Algorithm::Odometer::Tiny->new( (['0'..'9','a'..'z']) x 4 );
	my ($cnt,@o)=0;
	while (<$odo>) {
		push @o, $_;
		last if ++$cnt>=100;
	}
	is_deeply \@o, [qw/ 0000 0001 0002 0003 0004 0005 0006 0007 0008
		0009 000a 000b 000c 000d 000e 000f 000g 000h 000i 000j 000k 000l 
		000m 000n 000o 000p 000q 000r 000s 000t 000u 000v 000w 000x 000y 
		000z 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 001a 001b 
		001c 001d 001e 001f 001g 001h 001i 001j 001k 001l 001m 001n 001o 
		001p 001q 001r 001s 001t 001u 001v 001w 001x 001y 001z 0020 0021 
		0022 0023 0024 0025 0026 0027 0028 0029 002a 002b 002c 002d 002e 
		002f 002g 002h 002i 002j 002k 002l 002m 002n 002o 002p 002q 002r /],
			'longer list';
}

{
	my @wheels = ( ['foo','bar'], [3..6], ['quz','baz'] );
	my $odo = Algorithm::Odometer::Gray->new(@wheels);
	# note the following generates two "used only once" warnings on Perls 5.8 thru 5.18, that's ok
	my $exp_len = reduce { $a * $b } map {0+@$_} @wheels; # product() was added in List::Util 1.35
	is $exp_len, 16, 'expected length calc is correct';
	my @c = $odo->();
	is_deeply \@c, ['foo','3','quz'], 'basic ::Gray test 1/2';
	my @o;
	while (<$odo>) { push @o, $_ }
	is_deeply \@o, [qw/ bar3quz bar4quz foo4quz foo5quz bar5quz bar6quz foo6quz
		foo6baz bar6baz bar5baz foo5baz foo4baz bar4baz bar3baz foo3baz /],
		'basic ::Gray test 2/2' or diag explain \@o;
	is $odo->(), 'foo3quz', "re-start 1/2";
	is $odo->(), 'bar3quz', "re-start 2/2";
}

subtest 'undefs' => sub { plan tests=>3;
	is grep( {/uninitialized/i} warns {
		my $odo1 = Algorithm::Odometer::Tiny->new( ['a',undef,'c'],[1,2] );
		my @o1; push @o1, $_ while <$odo1>;
		is_deeply \@o1, [ qw/ a1 a2 1 2 c1 c2 / ], '::Tiny' or diag explain \@o1;
		my $odo2 = Algorithm::Odometer::Gray->new( ['a',undef,'c'],[1,2] );
		my @o2; push @o2, $_ while <$odo2>;
		is_deeply \@o2, [ qw/ a1 1 c1 c2 2 a2 / ], '::Gray' or diag explain \@o2;
	} ), 0, 'no uninitialized warnings';
};

SKIP: {
	skip "need Perl >= v5.18 for overloaded <> in list context",
		2 if $] lt '5.018'; # [perl #47119]
	my $odo1 = Algorithm::Odometer::Tiny->new( ['foo','bar'], [3..5] );
	is_deeply [<$odo1>], ["foo3", "foo4", "foo5", "bar3", "bar4", "bar5"], 'list context <> ::Tiny';
	my $odo2 = Algorithm::Odometer::Gray->new( ['a','b','c'],[1,2] );
	is_deeply [<$odo2>], ["a1", "b1", "c1", "c2", "b2", "a2"], 'list context <> ::Gray';
}

subtest 'errors' => sub { plan tests=>4;
	like exception { Algorithm::Odometer::Tiny->new() }, qr/\bno wheels specified\b/i, 'no wheels specified';
	like exception { Algorithm::Odometer::Gray->new() }, qr/\bno wheels specified\b/i, 'no wheels specified ::Gray';
	like exception { Algorithm::Odometer::Gray->new(['x','y'],['z']) }, qr/\bat least two positions\b/i, 'Gray at least two positions 1/2';
	like exception { Algorithm::Odometer::Gray->new(['x','y'],[]) }, qr/\bat least two positions\b/i, 'Gray at least two positions 2/2';
};

if ( my $cnt = grep {!$_} Test::More->builder->summary )
	{ BAIL_OUT("$cnt tests failed") }
done_testing(TESTCOUNT);
