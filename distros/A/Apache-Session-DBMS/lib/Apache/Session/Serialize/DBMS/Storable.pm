#############################################################################
#
# Apache::Session::Serialize::DBMS::Storable
# Serializes session objects using Storable and object-per-key support added
# for Apache::Session::DBMS module
#
# Copyright(c) 2005 Asemantics S.r.l.
# Alberto Reggiori (alberto@asemantics.com)
# Distribute under a BSD license (see LICENSE file in main dir)
#
############################################################################

package Apache::Session::Serialize::DBMS::Storable;

use strict;
use vars qw($VERSION);
use Storable qw(nfreeze thaw);

$VERSION = '0.1';

sub serialize {
	my $session = shift;

        if( $session->{isObjectPerKey} ) {
                my $data = shift;

                nfreeze( ref($data) ? $data : \$data );
        } else {
                $session->{serialized} = nfreeze $session->{data};
                };
        };

sub unserialize {
        my $session = shift;

        if( $session->{isObjectPerKey} ) {
                my $oldvalue = thaw(shift);

                ref($oldvalue)=~ /SCALAR/ ? ${$oldvalue} : $oldvalue;
        } else {
                $session->{data} = thaw $session->{serialized};
                };
        };

1;

=pod

=head1 NAME

Apache::Session::Serialize::DBMS::Storable - Use Storable to zip up persistent data

=head1 SYNOPSIS

 use Apache::Session::Serialize::DBMS::Storable;
 
 $zipped = Apache::Session::Serialize::DBMS::Storable::serialize($ref);
 $ref = Apache::Session::Serialize::DBMS::Storable::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of Storable's
C<nfreeze()> and C<thaw()> functions.  The result is a binary object ready
for storage.

=head1 AUTHOR

This module was written by Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

L<Apache::Session::DBMS>
