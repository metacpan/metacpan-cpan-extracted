#############################################################################
#
# Apache::Session::Serialize::Dumper
# Serializes session objects using Data::Dumper
# Copyright(c) 2000 Pascal Fleury (fleury@users.sourceforge.net)
# Distribute under the Artistic License
#
############################################################################

package Apache::Session::Serialize::Dumper;

use strict;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = "0.90";

sub serialize {
    my $session = shift;
	 local $Data::Dump::Purity = 1;
	 local $Data::Dumper::Varname = "ASSD";
    $session->{serialized} = Dumper( $session->{data} );
}

sub unserialize {
    my $session = shift;

	 my $ASSD1;
	 eval $session->{serialized};
    $session->{data} = $ASSD1;
}

1;

=pod

=head1 NAME

Apache::Session::Serialize::Dumper - Use Data::Dumper to zip up persistent data

=head1 SYNOPSIS

 use Apache::Session::Serialize::Dumper;
 
 $zipped = Apache::Session::Serialize::Dumper::serialize($ref);
 $ref = Apache::Session::Serialize::Dumper::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of Data::Dumper's
C<dump()> and Perl's C<eval()> functions.  The result is a text object
ready for storage.

=head1 AUTHOR

This module was written by Pascal Fleury <fleury@users.sourceforge.net>.

=head1 SEE ALSO

L<Data::Dumper>
L<Apache::Session::Serialize::Base64>,
L<Apache::Session::Serialize::Storable>,
L<Apache::Session>
