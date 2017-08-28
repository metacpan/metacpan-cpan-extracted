package Async::Stream::Iterator;

use 5.010;
use strict;
use warnings;

use Carp qw(croak);

=head1 NAME

Iterator for Async stream

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

Creating and managing item for Async::Stream

  use Async::Stream::Iterator;

  my $iterator = Async::Stream::Iterator->new($stream);

=head1 SUBROUTINES/METHODS

=head2 new($stream)

Constructor creates instance of class. 
Class method gets 1 arguments stream from which will be created iterator.

  my $iterator = Async::Stream::Iterator->new($stream);
=cut
sub new {
	my ($class, $item) = @_;

	if (!$item->isa('Async::Stream::Item')) {
		croak "First argument can be only instance of Async::Stream::Item or instance of derived class";
	}

	return bless sub {
			my $return_cb = shift;
			return $return_cb->() if (!defined $item);

			$item->next(sub {
				if (defined $_[0]) {
					$item = shift;
					$return_cb->($item->val);
					return;
				} else {
					$return_cb->();
					undef $item;
					return;
				}
			});
		}, $class;
}

=head2 next($returning_cb)

Method gets returning callback and call that when iterator ready to return next value.

  $iterator->(sub {
      my $item_value = shift;
    });
=cut

sub next {
	my $self = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE') {
		croak "First argument can be only subroutine reference"
	}

	$self->($return_cb);

	return;
}

=head1 AUTHOR

Kirill Sysoev, C<< <k.sysoev at me.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/pestkam/p5-Async-Stream/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Async::Stream::Item


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Kirill Sysoev.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Async::Stream::Item
