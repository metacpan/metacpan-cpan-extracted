package Capture::Attribute::Return;

use 5.010;
use strict;

BEGIN {
	$Capture::Attribute::Return::AUTHORITY = 'cpan:TOBYINK';
	$Capture::Attribute::Return::VERSION   = '0.003';
}

use Any::Moose;

use overload
	'@{}' => '_ARRAY',
	'""'  => '_SCALAR',
	'${}' => '_SCALAR';

has wasarray => (
	is        => 'ro',
	isa       => 'Num|Undef',
	required  => 1,
	);

has value => (
	is        => 'ro',
	required  => 0,
	predicate => 'has_value',
	);

sub _ARRAY
{
	my ($self) = @_;
	return [] if $self->is_void;
	return $self->wasarray ? $self->value : [ $self->value ];
}

sub _SCALAR
{
	my ($self) = @_;
	return undef if $self->is_void;
	$self->wasarray ? do { my @a = @{$self->value}; scalar(@a) } : $self->value;
}

sub is_list
{
	my ($self) = @_;
	return 1 if $self->wasarray;
	return;
}

sub is_scalar
{
	my ($self) = @_;
	my $wasarray = $self->wasarray;
	return if $wasarray;
	return 1 if defined $wasarray;
	return;
}

sub is_void
{
	my ($self) = @_;
	return if defined $self->wasarray;
	return 1;
}

__PACKAGE__
__END__

=head1 NAME

Capture::Attribute::Return - the result of a "return" statement

=head1 DESCRIPTION

This is an L<Any::Moose> class. Hopefully you'll never need to use it.

=head2 Constructor

=over

=item C<< new(%attributes) >>

=back

=head2 Attributes

=over

=item C<< wasarray >>

Indicates whether the returned value was the result of a function call in
"wantarray" mode or not. Either true, false or undef. See C<wantarray>
in L<perlfunc>.

=item C<< value >>

The return value, or if C<wasarray> is true, then a reference to an array
containing the list of returned values.

=back


=head2 Methods

=over

=item C<is_list>, C<is_scalar>, C<is_void>

Slightly nicer than fiddling with checking the definedness and truthiness
of C<wasarray>.

=back

=head2 Overloads

This class overloads array and scalar dereferencing.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Capture-Attribute>.

=head1 SEE ALSO

L<Capture::Attribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

