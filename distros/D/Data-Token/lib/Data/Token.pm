package Data::Token;
use warnings;
use strict;
use version; our $VERSION = qv('0.0.3');
use Data::UUID;
use Digest::SHA qw(sha1_hex);
use base qw/Exporter/;
use Crypt::Random qw( makerandom ); 
our @EXPORT = qw/token/;

sub token {
	our $uuid ||= new Data::UUID;
	our $secret ||= makerandom ( Size => 512, Strength => 0 ); 
	return sha1_hex($uuid->create_str() . $secret);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Data::Token - Generate an unpredictable unique token

=head1 VERSION

This document describes Data::Token version 0.0.3

=head1 SYNOPSIS

	use Data::Token;
	print token;

=head1 DESCRIPTION

This library exports a single method 'token' which can be used to generate a
unique and unpredictable token.

=head1 INTERFACE 

=head2 token

Return a unique token.

=head1 DATA

The data returned may change over time, but will be kept to characters between
A-Z, a-z, 0-9, _ and - and a maximum length of 256 characters (currently it is
much shorter).

It is safe to put in a URL (note: Length may become an issue in the future);
insert into a database (although you should always use BIND columns); as an
attribute or text section of XML (also HTML) (but not as a Tag name); store
as a filename on disk; key/value in a Hash etc.

=head1 SECURITY

These tokens are hard to guess. That does not mean there is no overlaps. Using
a hashing system such as MD5 or SHA-1 still means possibility of overlap. MD5
is a problem in signatures against large documents because you can change parts
of the document without changing the meaning. But this system is only using MD5
to hide the secret and add unpredictability. So MD5 or SHA-1 - Jury is out.

=head2 Duplicates

You should check for duplicates in your local store before returning. The
chances of duplicates are extremely unlikely but better safe than sorry.

=head2 Bruit force attack

Although the numbers are unpredictable there is alwas bruit force attacks.
These need to be guarded against. A system should increase the time delay on
requests as the attack increases. If you are using Apache this can be done with
other modules, or integrated into your solution.

=head1 INTEGRATION

This module is written to replace embedded modules in applications such as
CGI::Session, but also for non-standard modules you have to write yourself
(e.g. Creating a unique URL for returning private data).

=head1 DIAGNOSTICS

=over

XXX

=item C<< Error message here, perhaps with %s placeholders >>

=item C<< Another error message here >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

Data::Token requires no configuration files or environment variables.

=head1 DEPENDENCIES

Uses Data::UUID to create the initial unique number and md5 to generate the
unpredictability.

XXX Possibly SHA1 and Crypt::Random

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-token@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Scott Penrose  C<< <scott@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Scott Penrose C<< <scott@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
