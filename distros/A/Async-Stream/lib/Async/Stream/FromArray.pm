package Async::Stream::FromArray;

use 5.010;
use strict;
use warnings;

use base qw(Async::Stream);

use Carp qw(croak);

=head1 NAME

Use that class for creating streams from array.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

  use Async::Stream::FromArray;

  my @domains = qw(
    ucoz.com
    ya.ru
    googl.com
  );

  my $stream = Async::Stream::FromArray->new(@domains);
    
=head1 SUBROUTINES/METHODS


=head2 new(@array_of_items)

Constructor creates instance of class. 
Class method gets a list of items which are used for generating stream's items.
	
  my @domains = qw(
    ucoz.com
    ya.ru
    googl.com
  );
  
  my $stream = Async::Stream::FromArray->new(@urls)

=cut

sub new {
	my $class = shift;
	my $items = \@_;

	return $class->SUPER::new(
		sub { 
			$_[0]->( @{$items} ? (shift @{$items}) : () );
			return;
		}
	);
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

1; # End of Async::Stream::FromArray