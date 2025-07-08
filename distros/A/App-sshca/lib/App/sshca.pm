package App::sshca v0.0.3;

use strict;
use warnings;

1;

__END__

=head1 NAME

sshca - A minimal SSH Certificate Authority

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

  $ sshca init
  Successfully created SH CA directory ~/sshca
  $ sshca issue certName ~/.ssh/id_ed25519.pub
  User certificate with identity 'certName' and serial number 1:
  ... certificate data ...
  $ sshca renew 1
  ... certificate data ...

=head1 DESCRIPTION

This is a simple SSH Certificate Authority. SSH certificates greatly
enhance the functionality of SSH public keys. The C<sshca> script hands
out certificates for public keys and tracks these certs. It can be
used to create both user and host certificates.

Read more about SSH certificates in the following articles:

=over 8

=item * L<Tightening SSH access using short-lived SSH certificates|https://www.bastionxp.com/blog/tightening-ssh-access-using-short-lived-ssh-certificates/>

=item * L<How to configure and setup SSH certificates for SSH authentication|https://dev.to/gvelrajan/how-to-configure-and-setup-ssh-certificates-for-ssh-authentication-b52>

=item * L<Server access with SSH certificates - deep dive|https://dev.to/ehuelsmann/server-access-with-ssh-certificates-deep-dive-4h05>

=back

=head1 COMMANDS

=head2 init

  sshca [global-options] init [options] <ca-directory>

Creates a certificate authority administrative directory C<ca-directory>.

Available options:

=over 8

=item * C<< --serial=<number> >>

Used to override the initial serial number (defaults to 1)

=back

=head2 issue

  sshca [global-options] issue [options] <identity> <pubkey filename>

Issues a new user certificate for the public key read from C<< <pubkey filename> >>.
If the filename is equal to C<-> (hyphen), the public key data is read from
standard input.

Available options:

=over 8

=item * C<--host>

When provided, issues a host certificate instead of a user certificate

=item * C<< --option=<option> >>

Add the given option to the certificate; this option may be passed multiple times

=item * C<< --principal=<principal> >>

Adds the given principal to the certificate; this option may be passed multiple times.
Principles on "host" certificates must be host names or IP addresses; principles on
"user" certificates the values are documented to be user names, but can also be used
as the more general concept of tags.

=back

=head2 renew

  sshca [global-options] renew <identifier>

Issues a new certificate using the input data that was provided to generate the
certificate with serial number C<identifier>, except for the validity period.

Available options:

=over 8

=item * C<--serial>|C<--fingerprint>|C<--identity>

Used to change the interpretation of the C<identifier> argument.

=over 8

=item * C<--serial> indicates the identifier argument is to be interpreted as a
certificate serial number.

=item * (planned) C<--fingerprint> indicates the identifier argument is to be
interpreted as a public key finger print; in case multiple certificates have been
issued for this public key the last issued certificate is renewed.

=item * (planned) C<--identity> indicates the identifier argument is to be
interpreted as a certificate identity; in case multiple certificates have been
issued for this identity the last issued certificate is renewed.

=back

=item * C<--validity>

Indicates the validity period of the new certificate.

=back

=head2 revoke

Planned.

=head2 history

Planned.

=head1 GLOBAL OPTIONS

These options can be specified before commands and are accepted with all commands:

=over 8

=item * C<--debug>

=item * C<--config> (ignored on C<init> command)

=item * C<--basedir> (ignored on C<init> command)

=back

=head1 ENVIRONMENT VARIABLES

Environment variables override hard-coded defaults as well as configuration values.
Command line options take precedence over environment variables.

=head2 SSHCA_CONF

Used to specify the location of the configuration file, disabling the built-in
list of locations to be tried.

=head2 SSHCA_HOME

Used to override the location of the administrative files.

=head1 CONFIGURATION

The configuration file (C<sshca.conf>) is a YAML file with the following keys:

=over 8

=item * C<basedir>

=item * C<ca_keytype>

Default: C<ed25519>

=item * C<hostcert_validity>

Default: C<+53w>

=item * C<usercert_validity>

Default: C<+13w1d>

=back

=head1 FUTURE DEVELOPMENT

The current version stores the certificate data in the filesystem. Next iterations
should be more flexible and contain configurable storage backends, e.g. using DBI
which would allow storing the data in SQLite or PostgreSQL.

=head1 SEE ALSO

=over 8

=item * L<sshca (shell script)|https://github.com/mattferris/sshca>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2025 Erik Huelsmann <ehuels@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
