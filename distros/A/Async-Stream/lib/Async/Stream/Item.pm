package Async::Stream::Item;

use 5.010;
use strict;
use warnings;

use Carp;


use constant {
	VALUE => 0,
	NEXT  => 1,
	QUEUE => 2,
};

=head1 NAME

Item for Async::Stream

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Creating and managing item for Async::Stream

  use Async::Stream::Item;

  my $stream_item = Async::Stream::Item->new($value, $next_item_cb);
		
=head1 SUBROUTINES/METHODS

=head2 new($val,$generator)

Constructor creates instance of class. 
Class method gets 2 arguments item's value and generator subroutine references to generate next item.

  my $i = 0;
  my $stream_item = Async::Stream::Item->new($i++, sub {
      my $return_cb = shift;
      if($i < 100){
				$return_cb->($i++)
      } else {
				$return_cb->()
      }
    });

=cut

sub new {
	my ($class, $val, $next) = @_;

	if (ref $next ne "CODE" and ref $next ne $class) {
		croak "Second argument can be only subroutine reference or instance of class $class ";
	}

	return bless [ $val, $next, []], $class;
}

=head2 val()

Method returns item's value.

  my $value = $stream_item->val;

=cut

sub val {
	return $_[0]->[VALUE];
}

=head2 next($next_callback);
	
Method returns next item in stream. Method gets callback to return next item.

  $stream_item->next(sub {
      my $next_stream_item = shift;
    });

=cut

sub next {
	my $self = shift;
	my $next_cb = shift;

	if (ref $next_cb ne "CODE") {
		croak "First argument can be only subroutine reference";
	}

	if (ref $self->[NEXT] eq "CODE") {
		push @{$self->[QUEUE]}, $next_cb;
		if (@{$self->[QUEUE]} == 1) {
			$self->[NEXT](sub {
				my @response;
				if (@_) {
					$self->[NEXT] = ref($self)->new($_[0], $self->[NEXT]);
					@response = ($self->[NEXT]);
				} else {
					$self->[NEXT] = undef;
				}

				for my $next_cb (@{$self->[QUEUE]}) {
					$next_cb->(@response);
				}
			});
		}
	} else {
		$next_cb->($self->[NEXT]);
	}
	
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
