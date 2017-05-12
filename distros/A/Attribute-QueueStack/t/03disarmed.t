=pod

=encoding utf-8

=head1 PURPOSE

Test basic L<Attribute::QueueStack> functionality when armed.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# line 23 "t/02armed.t"

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN { $ENV{PERL_QUEUESTACK_LOOSE} = 1 };
use Attribute::QueueStack;

ok(!Attribute::QueueStack::ARMED, "completely 'armless")
	or BAIL_OUT('expected Attribute::QueueStack to be disarmed!');

my @Q :Queue;
my @S :Stack;

ok(
	!tied(@Q),
	'@Q not tied',
);

# permitted operations for queue throw no errors
push @Q, qw(Foo Bar Baz);
is(@Q, 3, 'length of queue');
is($Q[0], 'Foo', 'peek at queue');
is(shift(@Q), 'Foo', 'shift queue');
is(@Q, 2, 'length of queue has changed');
@Q = ();
is(@Q, 0, 'queue can be cleared');
push @Q, qw(Foo Bar Baz);

is(
	exception { pop @Q },
	undef,
	'disarmed: pop from queue not permitted',
);

is(
	exception { unshift @Q, "Quux" },
	undef,
	'disarmed: unshift to queue not permitted',
);

is(
	exception { $Q[1] },
	undef,
	'disarmed: queue peek-ahead not permitted',
);

is(
	exception { $Q[0] = "Flibble" },
	undef,
	'disarmed: store to queue not permitted',
);

ok(
	!tied(@S),
	'@S not tied',
);

# permitted operations for stack throw no errors
push @S, qw(Foo Bar Baz);
is(@S, 3, 'size of stack');
is($S[-1], 'Baz', 'peek at stack');
is($S[$#S], 'Baz', 'peek at stack - using stack size');
is(pop(@S), 'Baz', 'pop stack');
is(@S, 2, 'size of has changed');
@S = ();
is(@S, 0, 'stack can be cleared');
push @S, qw(Foo Bar Baz);

is(
	exception { shift @S },
	undef,
	'disarmed: shift from stack not permitted',
);

is(
	exception { unshift @S, "Quux" },
	undef,
	'disarmed: unshift to stack not permitted',
);

is(
	exception { $S[1] },
	undef,
	'disarmed: stack peek-behind not permitted',
);

is(
	exception { $S[-1] = "Flibble" },
	undef,
	'disarmed: store to stack not permitted',
);

done_testing;

