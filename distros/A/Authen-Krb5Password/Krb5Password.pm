package Authen::Krb5Password;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(kpass);
$VERSION = '1.03';

bootstrap Authen::Krb5Password $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Authen::Krb5Password - Perl extension for Kerberos 5 password verification

=head1 SYNOPSIS

  use Authen::Krb5Password;
  $success = kpass("username", "password", "service", "host", "FILE:/path/to/keytab");

=head1 DESCRIPTION

This module provides a Perl function to perform password verification
using Kerberos 5. It is intended for use by applications that cannot
use the Kerberos protocol directly. If it must be run on a system that 
receives a username and password over the network, steps should be 
taken to ensure that these are passed to the server in a cryptographically
secure manner.

kpass() attempts to obtain credentials for the given username and password
from the Kerberos AS, then obtain credentials for a local service from the
Kerberos TGS to verify the authenticity of the AS response. Empty strings 
can be passed as the 3rd and/or 4th arguments to use the default service 
name ("host") and the fully canonicalized primary hostname of the system 
that the function is executed on. The fifth argument may be omitted to use 
the system's default keytab file.

kpass() returns -1 if an error occurs, 0 if the username or password is
incorrect, or 1 if password verification is successful. Errors and
authentication failures are recorded via syslog(3). Because of deficiencies
in Perl's syslog implementation in Sys::Syslog(3), there's no clean way
to log output to any facility other than the default LOG_USER. One
possible way around this problem is to use the Unix::Syslog module
available on CPAN, which correctly uses your platform's native syslog
library routines to perform the functions.

=head1 SEE ALSO

openlog(3), perl(1), syslog(3), Sys::Syslog(3).

=cut
