#############################################################################
#
# Apache::Session::Serialize::DBMS::YAML
# Serializes session objects using YAML and object-per-key support added
# for Apache::Session::DBMS module
#
# Copyright(c) 2005 Asemantics S.r.l.
# Alberto Reggiori (alberto@asemantics.com)
# Distribute under a BSD license (see LICENSE file in main dir)
#
############################################################################

package Apache::Session::Serialize::DBMS::YAML;

use strict;
use vars qw($VERSION);
use YAML ();

$VERSION = '0.1';

sub serialize {
	my $session = shift;

        if( $session->{isObjectPerKey} ) {
		YAML::Dump( shift );
        } else {
		$session->{serialized} = YAML::Dump($session->{data});
                };
        };

sub unserialize {
        my $session = shift;

        if( $session->{isObjectPerKey} ) {
		YAML::Load( shift );
        } else {
		$session->{data} = YAML::Load($session->{serialized});
                };
        };

1;

=pod

=head1 NAME

Apache::Session::Serialize::DBMS::YAML - Use YAML to zip up persistent data

=head1 SYNOPSIS

 use Apache::Session::Serialize::DBMS::YAML;
 
 $zipped = Apache::Session::Serialize::DBMS::YAML::serialize($ref);
 $ref = Apache::Session::Serialize::DBMS::YAML::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of YAML's
C<Dump()> and C<Load()> functions.  The result is a binary object ready
for storage.

=head1 AUTHOR

This module was written by Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

L<Apache::Session::DBMS>, L<YAML>
