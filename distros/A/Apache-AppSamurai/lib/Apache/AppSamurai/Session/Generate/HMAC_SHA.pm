# Apache::AppSamurai::Session::Generate::HMAC_SHA - Apache::Session generator
#                                module.  Replaces MD5 generator with one that
#                                takes input server key and client session key
#                                and returns the SHAx HMAC of the two.

# $Id: HMAC_SHA.pm,v 1.9 2008/04/30 21:40:10 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

package Apache::AppSamurai::Session::Generate::HMAC_SHA;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = substr(q$Revision: 1.9 $, 10, -1);

use Digest::SHA qw(sha256_hex hmac_sha256_hex);

# Instead of adding even more options, I decided to just use SHA-256.
# This is the length in hex digits.
my $length = 64;

sub generate {
    my $session = shift;
    my $server_key = '';

    (exists $session->{args}->{ServerKey}) or die "HMAC session support requires a ServerKey";

    # ServerKey should already be hashed for us
    (&checkhash($session->{args}->{ServerKey})) or die "Invalid ServerKey";
 
    (exists $session->{args}->{key}) or die "HMAC session support requires a per-session Authentication Key (key)";
    (&checkhash($session->{args}->{key})) or die "Invalid Session Authentication Key";
    $session->{data}->{_session_id} = hmac_sha256_hex($session->{args}->{key},$session->{args}->{ServerKey});

    return $session->{data}->{_session_id};
}

sub validate {
    #This routine checks to ensure that the session ID is in the form
    #we expect.  This must be called before we start diddling around
    #in the database or the disk.

    my $session = shift;
    
    unless (&checkhash($session->{data}->{_session_id})) {
        die "Invalid Session ID Value";
    }
}

# Check for a hex encoded hash of $length
sub checkhash {
    my $hash = shift;

    if ($hash =~ /^[a-fA-F0-9]{$length}$/) {
	return 1;
    }
    return 0;
}

1; # End of Apache::AppSamurai::Session::Generate::HMAC_SHA

__END__

=head1 NAME

Apache::AppSamurai::Session::Generate::HMAC_SHA - HMAC/SHA256 session
generator for Apache::AppSamurai::Session

=head1 SYNOPSIS

 use Apache::AppSamurai::Session::Generate::HMAC_SHA;
 
 # A server key and session authentication key are required and must be
 # sent in a hash reference as shown below.  Static server key and
 # session authentication keys are shown for the sake of the example.
 $session->{args}->{ServerKey} = "628b49d96dcde97a430dd4f597705899e09a968f793491e4b704cae33a40dc02";
 $session->{args}->{key} = "c44474038d459e40e4714afefa7bf8dae9f9834b22f5e8ec1dd434ecb62b512e";
 $id = Apache::AppSamurai::Session::Generate::HMAC_SHA::generate($session);
 
 # Note - this is not how you will see this module generally called.
 # Instead, you will see it called by reference from Apache::Session or
 # Apache::AppSamurai::Session. 

 # Validate the session ID format
 (Apache::AppSamurai::Session::Generate::HMAC_SHA::validate($id)) or die "Bad!";

=head1 DESCRIPTION

This module fulfills the ID generation interface of
L<Apache::Session|Apache::Session> and
L<Apache::AppSamurai::Session|Apache::AppSamurai::Session>.

Unlike the normal Apache::Session generators like MD5, this requires two
input values: A server key and a session authentication key.  Both must
be hex string encoded 256 bit values.  The values are passed in a hash
reference, (see examples).  The values are then punched into a HMAC using
SHA256 as the digest.  The ID is returned by the generate function, and
the function also sets the {data}->{session_id} value on the passed in
session hash.

This module can also examine session IDs to ensure that they are, indeed,
session ID numbers and not evil attacks.  The reader is encouraged to 
consider the effect of bogus session ID numbers in a system which uses
these ID numbers to access disks and databases.

This modules takes no direct arguments when called as an object, but expects
$self to include a hash reference named "args" from which to extract the
server key and session authentication key.

=head1 SEE ALSO

L<Apache::AppSamurai::Session>, L<Digest::SHA>, L<Apache::Session>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

See L<Apache::AppSamurai> for information on bug submission and tracking.

=head1 SUPPORT

See L<Apache::AppSamurai> for support information.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
