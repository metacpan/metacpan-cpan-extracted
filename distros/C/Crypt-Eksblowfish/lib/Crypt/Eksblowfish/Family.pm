=head1 NAME

Crypt::Eksblowfish::Family - Eksblowfish cipher family

=head1 SYNOPSIS

	use Crypt::Eksblowfish::Family;

	$family = Crypt::Eksblowfish::Family->new_family(8, $salt);

	$cost = $family->cost;
	$salt = $family->salt;
	$block_size = $family->blocksize;
	$key_size = $family->keysize;
	$cipher = $family->new($key);

=head1 DESCRIPTION

An object of this class represents an Eksblowfish cipher family.
It contains the family parameters (cost and salt), and if combined
with a key it yields an encryption function.  See L<Crypt::Eksblowfish>
for discussion of the Eksblowfish algorithm.

It is intended that an object of this class can be used in situations
such as the "-cipher" parameter to C<Crypt::CBC>.  Normally that parameter
is the name of a class, such as "Crypt::Rijndael", where the class
implements a block cipher algorithm.  The class provides a C<new>
constructor that accepts a key.  In the case of Eksblowfish, the key
alone is not sufficient.  An Eksblowfish family fills the role of block
cipher algorithm.  Therefore a family object is used in place of a class
name, and it is the family object the provides the C<new> constructor.

=head2 Crypt::CBC

C<Crypt::CBC> itself has a problem, with the result that this class can
no longer be used with it in the manner originally intended.

When this class was originally designed, it worked with C<Crypt::CBC>
as described above: an object of this class would be accepted by
C<Crypt::CBC> as a cipher algorithm, and C<Crypt::CBC> would happily
supply it with a key and encrypt using the resulting cipher object.
C<Crypt::CBC> didn't realise it was dealing with a family object, however,
and there was some risk that a future version might accidentally squash
the object into a string, which would be no use.  In the course of
discussion about regularising the use of cipher family objects, the
author of C<Crypt::CBC> got hold of the wrong end of the stick, and
ended up changing C<Crypt::CBC> in a way that totally breaks this usage,
rather than putting it on a secure footing.

The present behaviour of C<Crypt::CBC> is that if an object (rather
than a class name) is supplied as the "-cipher" parameter then it has
a completely different meaning from usual.  In this case, the object
supplied is used as the keyed cipher, rather than as a cipher algorithm
which must be given a key.  This bypasses all of C<Crypt::CBC>'s usual
keying logic, which can hash and salt a passphrase to generate the key.
It is arguably a useful feature, but it's a gross abuse of the "-cipher"
parameter and a severe impediment to the use of family-keyed cipher
algorithms.

This class now provides a workaround.  For the benefit of C<Crypt::CBC>,
and any other crypto plumbing that requires a keyable cipher algorithm
to look like a Perl class (rather than an object), a family object
of this class can in fact be reified as a class of its own.  See the
method L</as_class>.

=cut

package Crypt::Eksblowfish::Family;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Crypt::Eksblowfish 0.005;
use Class::Mix 0.001 qw(genpkg);

our $VERSION = "0.009";

=head1 CONSTRUCTOR

=over

=item Crypt::Eksblowfish::Family->new_family(COST, SALT)

Creates and returns an object representing the Eksblowfish cipher
family specified by the parameters.  The SALT is a family key, and must
be exactly 16 octets.  COST is an integer parameter controlling the
expense of keying: the number of operations in key setup is proportional
to 2^COST.

=cut

sub new_family {
	my($class, $cost, $salt) = @_;
	return bless({ cost => $cost, salt => $salt }, $class);
}

=back

=head1 METHODS

=over

=item $family->cost

Extracts and returns the cost parameter.

=cut

sub cost { $_[0]->{cost} }

=item $family->salt

Extracts and returns the salt parameter.

=cut

sub salt { $_[0]->{salt} }

=item $family->blocksize

Returns 8, indicating the Eksblowfish block size of 8 octets.

=cut

sub blocksize { 8 }

=item $family->keysize

Returns 0, indicating that the key size is variable.  This situation is
handled specially by C<Crypt::CBC>.

=cut

sub keysize { 0 }

=item $family->new(KEY)

Performs key setup on a new instance of the Eksblowfish algorithm,
returning the keyed state.  The KEY may be any length from 1 octet to 72
octets inclusive.  The object returned is of class C<Crypt::Eksblowfish>;
see L<Crypt::Eksblowfish> for the encryption and decryption methods.

Note that this method is called on a family object, not on the class
C<Crypt::Eksblowfish::Family>.

=cut

sub new {
	my($self, $key) = @_;
	croak "Crypt::Eksblowfish::Family::new is not a class method ".
			"(perhaps you want new_family instead)"
		if ref($self) eq "";
	return Crypt::Eksblowfish->new($self->{cost}, $self->{salt}, $key);
}

=item $family->encrypt

This method nominally exists, to satisfy C<Crypt::CBC>.  It can't really
be used: it doesn't make any sense.

=cut

sub encrypt { croak "Crypt::Eksblowfish::Family::encrypt called" }

=item $family->as_class

Generates and returns (the name of) a Perl class that behaves as a
keyable cipher algorithm identical to this Eksblowfish cipher family.
The same methods that can be called as instance methods on $family can
be called as class methods on the generated class.

You should prefer to use the family object directly wherever you can.
Aside from being a silly indirection, the classes generated by this
method cannot be garbage-collected.  This method exists only to cater to
C<Crypt::CBC>, which requires a keyable cipher algorithm to look like a
Perl class, and won't operate correctly on one that looks like an object.

=cut

sub as_class {
	my($self) = @_;
	return $self->{as_class} ||= do {
		my $pkg = genpkg(__PACKAGE__."::");
		no strict "refs";
		@{"${pkg}::ISA"} = (ref($self));
		*{"${pkg}::new_family"} =
			sub { croak $_[0]."->new_family called" };
		*{"${pkg}::cost"} = sub { $self->cost };
		*{"${pkg}::salt"} = sub { $self->salt };
		*{"${pkg}::new"} = sub { shift; $self->new(@_) };
		*{"${pkg}::as_class"} = sub { $pkg };
		$pkg;
	};
}

=back

=head1 SEE ALSO

L<Crypt::CBC>,
L<Crypt::Eksblowfish>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
