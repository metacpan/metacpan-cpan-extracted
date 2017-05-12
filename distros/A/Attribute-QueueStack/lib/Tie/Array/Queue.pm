use 5.006;
use strict;
use warnings;

package Tie::Array::Queue;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Carp;
use Tie::Array ();
our @ISA = qw(Tie::StdArray);

eval qq[
	sub $_ { croak "$_ operation not permitted on queue" } 1
] || die $@ for qw(STORE POP UNSHIFT EXISTS DELETE SPLICE);

sub FETCH
{
	my $self = shift;
	
	# The first item on the stack can be peeked at.
	if ($_[0] == 0)
	{
		return $self->SUPER::FETCH(@_);
	}
	
	croak "FETCH operation not permitted on queue";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Tie::Array::Queue - force an array to act like a queue

=head1 SYNOPSIS

   use Tie::Array::Queue;
   
   tie my @q, "Tie::Array::Queue";

=head1 DESCRIPTION

See L<Attribute::QueueStack> for my interpretation of how queues act.

=head1 ENVIRONMENT

This module is unaffected by any environment variables.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Attribute-QueueStack>.

=head1 SEE ALSO

L<Attribute::QueueStack>, L<Tie::Array::Stack>.

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

