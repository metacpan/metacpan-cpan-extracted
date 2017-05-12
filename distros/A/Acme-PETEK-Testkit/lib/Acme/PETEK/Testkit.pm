package Acme::PETEK::Testkit;

use strict;
use vars qw($VERSION);

=head1 NAME

Acme::PETEK::Testkit - Perl module codebase for Tester's Toolkit

=head1 VERSION

Version 1.00

=cut

$VERSION = '1.00';

=head1 SYNOPSIS

This Perl module is intended to be a collection of sample code for
the Tester's Toolkit presentation at YAPC::NA 2005 by the author.

=for example begin

  use Acme::PETEK::Testkit;
  my $c = Acme::PETEK::Testkit->new;
  $c->incr;

=for example end

=begin testing

  my $c = Acme::PETEK::Testkit->new;
  $c->incr;
  cmp_ok($c->value,'==',1,'incr sends value to 1');

=end testing

=head1 CONSTRUCTOR

=head2 $kit = Acme::PETEK::Testkit->new()

Creates a new C<Acme::PETEK::Testkit> object,
which will be used for the object interface below.

=cut

sub new {
	my $class = shift;
	my $self = {
		_counter => 0,
	};
	return bless $self, $class;
}

=head1 OBJECT METHODS

=head2 $kit->reset( $int );

Resets the value of the stored counter, optionally setting it to $int.

=cut

sub reset {
	my ($self, $int) = @_;
	$int = 0 unless defined($int);
	$self->{'_counter'} = $int;
	return $self->value;
}

=head2 $kit->incr( $int );

Increment the counter by 1.  If C<$int> is provided, increment by that.
Returns the current value of the counter.

=cut

sub incr {
	my ($self, $int) = @_;
	$int = 1 unless defined($int);
	$self->{'_counter'} += $int;
	return $self->value;
}

=head2 $kit->decr( $int );

Decrement the counter by 1.  If C<$int> is provided, decrement by that.
Returns the current value of the counter.

=cut

sub decr {
	my ($self, $int) = @_;
	$int = 1 unless defined($int);
	$self->{'_counter'} -= $int;
	return $self->value;
}

=head2 $kit->value;

Returns the current value of the counter.

=cut

sub value {
	my $self = shift;
	return $self->{'_counter'};
}

=head2 $kit->sign

Returns "positive" or "negative" based on the value of the counter.

=cut

sub sign {
	my $self = shift;
	return 'negative' if $self->{'_counter'} < 0;
	return 'positive';
}

=head1 CLASS METHODS

=head2 add($int, $int)

Adds the two integers together and returns the result.

=cut

sub add {
	my ($int1, $int2) = @_;
	return $int1 + $int2;
}

=head2 subtract($int, $int)

Subtracts the second integer from the first and returns the result.

=cut

sub subtract {
	my ($int1, $int2) = @_;
	return $int1 - $int2;
}

=head1 AUTHOR

Pete Krawczyk, C<< <petek@cpan.org> >>

=head1 BUGS

Fix 'em yourself! :-)

=head1 ALSO SEE

Slides from the presentation are available at L<http://www.bsod.net/~petek/slides/>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Pete Krawczyk, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This library has also been released under a Creative Commons license
at the request of the YAPC::NA 2005 organizers. See
L<http://creativecommons.org/licenses/by/2.0/ca/> for more information;
in short, please give credit to the author should you use this code
elsewhere.

=cut

1; # End of Acme::PETEK::Testkit
