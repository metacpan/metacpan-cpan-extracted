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

BEGIN { $ENV{PERL_QUEUESTACK_STRICT} = 1 };
use Attribute::QueueStack;

ok(Attribute::QueueStack::ARMED, 'armed and deadly')
	or BAIL_OUT('expected Attribute::QueueStack to be armed!');

my @Q :Queue;
my @S :Stack;

isa_ok(
	tied(@Q),
	'Tie::Array::Queue',
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

like(
	exception { pop @Q },
	qr{^POP operation not permitted on queue at t/02armed.t},
	'pop from queue not permitted',
);

like(
	exception { unshift @Q, "Quux" },
	qr{^UNSHIFT operation not permitted on queue at t/02armed.t},
	'unshift to queue not permitted',
);

like(
	exception { $Q[1] },
	qr{^FETCH operation not permitted on queue at t/02armed.t},
	'queue peek-ahead not permitted',
);

like(
	exception { $Q[0] = "Flibble" },
	qr{^STORE operation not permitted on queue at t/02armed.t},
	'store to queue not permitted',
);

isa_ok(
	tied(@S),
	'Tie::Array::Stack',
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

like(
	exception { shift @S },
	qr{^SHIFT operation not permitted on stack at t/02armed.t},
	'shift from stack not permitted',
);

like(
	exception { unshift @S, "Quux" },
	qr{^UNSHIFT operation not permitted on stack at t/02armed.t},
	'unshift to stack not permitted',
);

like(
	exception { $S[1] },
	qr{^FETCH operation not permitted on stack at t/02armed.t},
	'stack peek-behind not permitted',
);

like(
	exception { $S[-1] = "Flibble" },
	qr{^STORE operation not permitted on stack at t/02armed.t},
	'store to stack not permitted',
);

done_testing;

