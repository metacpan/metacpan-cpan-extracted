use 5.006;
use strict;
use warnings;

package Attribute::QueueStack;

use Attribute::Handlers;
use Devel::StrictMode;

BEGIN {
	$Attribute::QueueStack::AUTHORITY = 'cpan:TOBYINK';
	$Attribute::QueueStack::VERSION   = '0.003';
}

sub _detect_strict ()
{
	return 0 if $ENV{PERL_QUEUESTACK_LOOSE};
	return 1 if STRICT;
	return 1 if $ENV{PERL_QUEUESTACK_STRICT};
	return 0;
}

BEGIN { *ARMED = _detect_strict ? sub () { !!1 } : sub () { !!0 } };

sub UNIVERSAL::Queue :ATTR(ARRAY)
{
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
	if (ARMED)
	{
		require Tie::Array::Queue;
		tie @$referent, "Tie::Array::Queue";
	}
	return;
}

sub UNIVERSAL::Stack :ATTR(ARRAY)
{
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
	if (ARMED)
	{
		require Tie::Array::Stack;
		tie @$referent, "Tie::Array::Stack";
	}
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Attribute::QueueStack - designate an array as a queue or a stack

=head1 SYNOPSIS

   my @todo :Queue;
   
   push @todo, qw(foo bar baz);
   shift @todo;
   
   # Naughty! Should only remove things from front of queue!
   pop @todo;

=head1 DESCRIPTION

This allows you to designate an array as either a queue or a stack.

Under normal circumstances, it acts as a no-op. In other words, your
array is unaffected by the presence of the attributes.

However, if Perl is run with certain environment variables set (see
L<Devel::StrictMode>), Attribute::QueueStack suddenly goes into deadly
mode, and complains if you try to abuse an array or queue.

Why this state of affairs? Well, this module works via tied arrays.
Perl's C<tie> mechanism is pretty slow. So the idea is that you'd want
the slow but strict behaviour in your development and testing environment,
but are happy to have it switched off for speed in your production
environment. (Bugs never occur in your production environment because
of your thorough testing process, right?!)

A constant C<< Attribute::QueueStack::ARMED >> can be used to determine
the state of Attribute::QueueStack.

=begin trustme

=item ARMED

=end trustme

=head2 Queues

Queues are first-in-first-out (FIFO). The following operations are
allowed on them:

=over

=item C<< my @queue :Queue >>

Declare a queue.

=item C<< push @queue, @items >>

You can add one or more items to the back of the queue.

=item C<< shift @queue >>

You can retrieve the first item from the queue.

=item C<< $queue[0] >>

You can peek at the first item in the queue.

=item C<< scalar(@queue) >>

You can find the length of the queue.

=item C<< @queue = () >>

You can empty the queue entirely.

=back

=head2 Stacks

Stacks are last-in-first-out (LIFO). The following operations are
allowed on them:

=over

=item C<< my @stack :Stack >>

Declare a stack.

=item C<< push @stack, @items >>

You can add one or more items to the top of the stack.

=item C<< pop @stack >>

You can retrieve the top item from the stack.

=item C<< $stack[-1] >>

You can peek at the last item on the stack.

=item C<< scalar(@stack) >>

You can find the height of the stack.

=item C<< @stack = () >>

You can empty the stack entirely.

=back

=head1 ENVIRONMENT

This module uses L<Devel::StrictMode> to determine if its attributes
should be enforced. The variables C<PERL_QUEUESTACK_LOOSE> and
C<PERL_QUEUESTACK_STRICT> may be used to override Devel::StrictMode's
decision.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Attribute-QueueStack>.

=head1 SEE ALSO

L<Devel::StrictMode>.

The following modules are used as part of the implementation of
Attribute::QueueStack, but can alternatively be used on their own:
L<Tie::Array::Queue>, L<Tie::Array::Stack>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

