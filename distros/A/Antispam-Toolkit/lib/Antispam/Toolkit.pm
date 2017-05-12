package Antispam::Toolkit;
BEGIN {
  $Antispam::Toolkit::VERSION = '0.08';
}

use strict;
use warnings;

1;

# ABSTRACT: Classes, roles, and types for use by other Antispam modules



=pod

=head1 NAME

Antispam::Toolkit - Classes, roles, and types for use by other Antispam modules

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This distribution provides a set of useful classes, roles, and types for use
by other Antispam modules. It's not really useful on its own.

=head1 ALPHA WARNING

This code is still quite new. The API it provides may change at any time.

=head1 INCLUDED MODULES

=head2 L<Antispam::Toolkit::Result>

A class for describing the result of a spam check.

=head2 L<Antispam::Toolkit::Types>

Exports some useful types using L<MooseX::Types>.

=head2 L<Antispam::Toolkit::Role::BerkeleyDB>

A role which can be used when you want to store data in a BerkeleyDB
database. This might be something like a list of known-bad ip addresses or
email addresses.

=head2 L<Antispam::Toolkit::Role::Database>

This is an interface-only role for classes that do some sort of database
lookup (SQL, Berkeley DB, etc.)

=head2 L<Antispam::Toolkit::Role::ContentChecker>

A role for classes which check whether a piece of content is spam.

=head2 L<Antispam::Toolkit::Role::EmailChecker>

A role for classes which check whether an email address is associated with spam

=head2 L<Antispam::Toolkit::Role::IPChecker>

A role for classes which check whether an IP address is associated with spam

=head2 L<Antispam::Toolkit::Role::URIChecker>

A role for classes which check whether a uri is linking to a spam site.

=head2 L<Antispam::Toolkit::Role::UsernameChecker>

A role for classes which check whether a user is a spammer.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-antispam-toolkit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

