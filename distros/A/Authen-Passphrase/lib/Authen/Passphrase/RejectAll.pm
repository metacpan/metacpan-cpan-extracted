=head1 NAME

Authen::Passphrase::RejectAll - reject all passphrases

=head1 SYNOPSIS

	use Authen::Passphrase::RejectAll;

	$ppr = Authen::Passphrase::RejectAll->new;

	$ppr = Authen::Passphrase::RejectAll
		->from_crypt("*");

	$ppr = Authen::Passphrase::RejectAll
		->from_rfc2307("{CRYPT}*");

	if($ppr->match($passphrase)) { ...

	$passwd = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class is a passphrase recogniser that accepts any
passphrase whatsoever.  This is a subclass of L<Authen::Passphrase>, and
this document assumes that the reader is familiar with the documentation
for that class.

This type of passphrase recogniser is obviously of no use at all in
controlling access to any resource.  Its use is to permit a resource
to be completely inaccessible in a system that expects some type of
passphrase access control.

=cut

package Authen::Passphrase::RejectAll;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

# There is only one object of this class, and its content is
# insignificant.

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::RejectAll->new

Returns a reject-all passphrase recogniser object.  The same object is
returned from each call.

=cut

{
	my $singleton = bless({});
	sub new { $singleton }
}

=item Authen::Passphrase::RejectAll->from_crypt(PASSWD)

Returns a reject-all passphrase recogniser object.  The same object is
returned from each call.  The argument, a crypt string, must be between
one and twelve (inclusive) characters long and must not start with "B<$>".

=cut

sub from_crypt {
	my($class, $passwd) = @_;
	if($passwd =~ /\A[^\$].{0,11}\z/s) {
		$passwd =~ /\A[!-#\%-9;-~][!-9;-~]{0,11}\z/
			or croak "malformed reject-all crypt data";
		return $class->new;
	}
	return $class->SUPER::from_crypt($passwd);
}

=item Authen::Passphrase::RejectAll->from_rfc2307(USERPASSWORD)

Generates a new reject-all passphrase recogniser object from an RFC
2307 string.  The string must consist of "B<{CRYPT}>" (case insensitive)
followed by an acceptable crypt string.

=back

=head1 METHODS

=over

=item $ppr->match(PASSPHRASE)

=item $ppr->as_crypt

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.
The L</match> method always returns false.

=cut

sub match { 0 }

sub as_crypt { "*" }

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
