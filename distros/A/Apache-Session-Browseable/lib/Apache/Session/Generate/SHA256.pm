# Directly copied from LemonLDAP::NG project (http://lemonldap-ng.org/)
package Apache::Session::Generate::SHA256;

use strict;
use vars qw($VERSION);
use Digest::SHA qw(sha256 sha256_hex sha256_base64);

$VERSION = '1.2.2';

sub generate {
    my $session = shift;
    my $length  = 64;

    if ( exists $session->{args}->{IDLength} ) {
        $length = $session->{args}->{IDLength};
    }

    $session->{data}->{_session_id} = substr(
        Digest::SHA::sha256_hex(
            Digest::SHA::sha256_hex( time() . {} . rand() . $$ )
        ),
        0, $length
    );

}

sub validate {

    #This routine checks to ensure that the session ID is in the form
    #we expect.  This must be called before we start diddling around
    #in the database or the disk.

    my $session = shift;

    if ( $session->{data}->{_session_id} =~ /^([a-fA-F0-9]+)$/ ) {
        $session->{data}->{_session_id} = $1;
    }
    else {
        die "Invalid session ID: " . $session->{data}->{_session_id};
    }
}

1;
