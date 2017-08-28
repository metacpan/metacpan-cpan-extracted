package Async::Stream::Pushable;

use 5.010;
use strict;
use warnings;

use base qw(Async::Stream);

use Carp qw(croak);

=head1 NAME

Use that class for creating streams which you can use to push item to them.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

Creating pushable streams, 
you can use this type of streams for example for observer pattern

  use Async::Stream::Pushable;

  my $stream = Async::Stream::Pushable->new;

  $stream->push(1,2,3)->finalize;

  # Or for example
  
  my $stream = Async::Stream::Pushable->new;

  $some_object->subscribe(sub {
      my $new_item = shift;
      $stream->push($new_item);
    });

    
=head1 SUBROUTINES/METHODS


=head2 new(@array_of_items)

Constructor creates instance of class. 
Class method create stream which you can use that to push items to that.

  my $stream = Async::Stream::Pushable->new(@urls)

=cut

sub new {
	my $class = shift;

	my $self;
	$self = $class->SUPER::new(
		sub {
			my ($return_cb) = @_;

			if (@{$self->{_items}}) {
				$return_cb->(shift @{ $self->{_items} });
			} else {
				if ($self->{_is_finalized}){
					$return_cb->();
				}
				else {
					push @{ $self->{_requests} }, $return_cb;	
				}
			}
		},
		@_,
	);

	$self->{_items}        = [];
	$self->{_requests}     = [];
	$self->{_is_finalized} = 0;

	return $self;
}

=head2 push(@new_items)

Push new items to stream

  my $stream->push(@new_items);

=cut
sub push {
	my ($self, @new_items) = @_;

	croak q{The stream is finalized} if ($self->{_is_finalized});

	while (@{ $self->{_requests} }) {
		my $return_cb = shift @{ $self->{_requests} };
		$return_cb->( shift @new_items );
	}

	if (@new_items) {
		push @{ $self->{_items} }, @new_items; 
	}

	return $self;
}

=head2 finalize()

Finalize stream

  my $stream->finalize;

=cut
sub finalize {
	my ($self) = @_;

	croak q{The stream has already been finalized} if ($self->{_is_finalized});

	$self->{_is_finalized} = 1;
}

=head1 AUTHOR

Kirill Sysoev, C<< <k.sysoev at me.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to 
L<https://github.com/pestkam/p5-Async-Stream/issues>.

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

1; # End of Async::Stream::Pushable