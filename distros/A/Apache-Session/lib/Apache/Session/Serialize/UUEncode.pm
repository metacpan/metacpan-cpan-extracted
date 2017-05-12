#############################################################################
#
# Apache::Session::Serialize::UUEncode
# Serializes session objects using Storable and pack
# Copyright(c) 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Serialize::UUEncode;

use strict;
use vars qw($VERSION);
use Storable qw(nfreeze thaw);

$VERSION = '1.01';

sub serialize {
    my $session = shift;
    
    $session->{serialized} = pack("u", nfreeze($session->{data}));
}

sub unserialize {
    my $session = shift;
    
    my $data = thaw(unpack("u", $session->{serialized}));
    die "Session could not be unserialized" unless defined $data;
    #Storable can return undef or die for different errors
    $session->{data} = $data;
}

1;

=pod

=head1 NAME

Apache::Session::Serialize::UUEncode - Use Storable and C<pack()>
to zip up persistent data

=head1 SYNOPSIS

 use Apache::Session::Serialize::UUEncode;

 $zipped = Apache::Session::Serialize::UUEncode::serialize($ref);
 $ref = Apache::Session::Serialize::UUEncode::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session. It
serializes the data in the session object by use of Storable's C<nfreeze()> and
C<thaw()> functions, and Perl's C<pack()> and C<unpack()>.  The serialized data
is ASCII text, suitable for storage in backing stores that don't handle binary
data gracefully, such as Postgres.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session::Serialize::Storable>, L<Apache::Session::Serialize::Base64>,
L<Apache::Session>
