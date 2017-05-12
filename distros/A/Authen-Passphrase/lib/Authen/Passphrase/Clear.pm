=head1 NAME

Authen::Passphrase::Clear - cleartext passphrases

=head1 SYNOPSIS

	use Authen::Passphrase::Clear;

	$ppr = Authen::Passphrase::Clear->new("passphrase");

	if($ppr->match($passphrase)) { ...

	$passphrase = $ppr->passphrase;

	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class is a passphrase recogniser that accepts
some particular passphrase which it knows.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

I<Warning:> Storing a passphrase in cleartext, as this class does,
is a very bad idea.  It means that anyone who sees the passphrase file
immediately knows all the passphrases.  Do not use this unless you really
know what you're doing.

=cut

package Authen::Passphrase::Clear;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

# An object of this class is a blessed scalar containing the passphrase.

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::Clear->new(PASSPHRASE)

Returns a passphrase recogniser object that stores the specified
passphrase in cleartext and accepts only that passphrase.

=cut

sub new {
	my($class, $passphrase) = @_;
	$passphrase = "$passphrase";
	return bless(\$passphrase, $class);
}

=item Authen::Passphrase::Clear->from_rfc2307(USERPASSWORD)

Generates a cleartext passphrase recogniser from the supplied RFC2307
encoding.  The string must consist of "B<{CLEARTEXT}>" (case insensitive)
followed by the passphrase.

=cut

sub from_rfc2307 {
	my($class, $userpassword) = @_;
	if($userpassword =~ /\A\{(?i:cleartext)\}/) {
		$userpassword =~ /\A\{.*?\}([!-~]*)\z/
			or croak "malformed {CLEARTEXT} data";
		my $text = $1;
		return $class->new($text);
	}
	return $class->SUPER::from_rfc2307($userpassword);
}

=back

=head1 METHODS

=over

=item $ppr->match(PASSPHRASE)

=item $ppr->passphrase

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.
The L</passphrase> method trivially works.

=cut

sub match {
	my($self, $passphrase) = @_;
	return $passphrase eq $$self;
}

sub passphrase { ${$_[0]} }

sub as_rfc2307 {
	my($self) = @_;
	croak "can't put this passphrase into an RFC 2307 string"
		if $$self =~ /[^!-~]/;
	return "{CLEARTEXT}".$$self;
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
