#############################################################################
#
# Apache::Session::Serialize::Sybase
# Serializes session objects using Storable and packing into Sybase format
# Copyright(c) 2000 Jeffrey William Baker (jwbaker@acm.org)
# Modified from Apache::Session::Serialize::Storable by Chris Winters (chris@cwinters.com)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Serialize::Sybase;

use strict;
use vars qw( $VERSION );

use Apache::Session::Serialize::Storable;

$VERSION = '1.00';

# Modify the storable-serialized data to work with sybase
sub serialize {
    my $session = shift;
	Apache::Session::Serialize::Storable::serialize( $session );    # sets $session->{serialized}
    $session->{serialized} = unpack('H*', $session->{serialized} );
}

# Modify the data from sybase to work with storable so it can thaw properly
sub unserialize {
    my $session = shift;
    $session->{serialized} = pack('H*', $session->{serialized} );
	Apache::Session::Serialize::Storable::unserialize( $session );  # sets $session->{data}
}

1;

=pod

=head1 NAME

Apache::Session::Serialize::Sybase - Use Storable to zip up persistent data and unpack/pack to put into Sybase-compatible image field

=head1 SYNOPSIS

 use Apache::Session::Serialize::Sybase;

 $zipped = Apache::Session::Serialize::Sybase::serialize($ref);
 $ref = Apache::Session::Serialize::Sybase::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session by
taking the data from Apache::Session::Serialize::Storable and modifying
it to work with Sybase IMAGE fields. Note that you do B<not> need to 
quote these values before inserting into the database, and that if you
are using DBI::Sybase, you cannot use the data in a placeholder. If you
use Apache::Session::Sybase as your session class, this will all 
get taken care of.

=head1 AUTHOR

Apache::Session::Serialize::Storable was written by 
Jeffrey William Baker <jwbaker@acm.org>; the Sybase-specific data
manipulation was written by Mark Landry <mdlandry@lincoln.midcoast.com>
for use in an earlier version of Apache::Session::DBI::Sybase and
placed here by Chris Winters <chris@cwinters.com>.

=head1 SEE ALSO

L<Apache::Session::Serialize::Storable>, L<Apache::Session::Sybase>
