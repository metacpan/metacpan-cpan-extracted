#############################################################################
#
# Apache::Session::Serialize::Storable
# Serializes session objects using Storable
# Copyright(c) 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Serialize::Storable;

use strict;
use vars qw($VERSION);
use Storable qw(nfreeze thaw);

$VERSION = '1.01';

sub serialize {
    my $session = shift;
    
    $session->{serialized} = nfreeze $session->{data};
}

sub unserialize {
    my $session = shift;
    
    my $data = thaw $session->{serialized};
    die "Session could not be unserialized" unless defined $data;
    #Storable can return undef or die for different errors
    $session->{data} = $data;
}

1;

=pod

=head1 NAME

Apache::Session::Serialize::Storable - Use Storable to zip up persistent data

=head1 SYNOPSIS

 use Apache::Session::Serialize::Storable;

 $zipped = Apache::Session::Serialize::Storable::serialize($ref);
 $ref = Apache::Session::Serialize::Storable::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of Storable's
C<nfreeze()> and C<thaw()> functions.  The result is a binary object ready
for storage.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session::Serialize::Base64>, L<Apache::Session>
