#############################################################################
#
# Apache::Session::Serialize::Base64
# Serializes session objects using Storable and MIME::Base64
# Copyright(c) 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Serialize::Base64;

use strict;
use vars qw($VERSION);
use MIME::Base64;
use Storable qw(nfreeze thaw);

$VERSION = '1.01';

sub serialize {
    my $session = shift;
    
    $session->{serialized} = encode_base64(nfreeze($session->{data}));
}

sub unserialize {
    my $session = shift;
    
    my $data = thaw(decode_base64($session->{serialized}));
    die "Session could not be unserialized" unless defined $data;
    #Storable can return undef or die for different errors
    $session->{data} = $data;
}

1;

=pod

=head1 NAME

Apache::Session::Serialize::Base64 - Use Storable and MIME::Base64
to zip up persistent data

=head1 SYNOPSIS

 use Apache::Session::Serialize::Base64;

 $zipped = Apache::Session::Serialize::Base64::serialize($ref);
 $ref = Apache::Session::Serialize::Base64::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of Storable's
C<nfreeze()> and C<thaw()> functions, and MIME::Base64's C<encode_bas64>
and C<decode_base64>.  The serialized data is ASCII text, suitable for
storage in backing stores that don't handle binary data gracefully, such
as Postgres.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session::Serialize::Storable>, L<Apache::Session>
