package App::SeismicUnixGui::messages::null_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self ) = @_;
    my @message;

    $message[0] = ("\n");

    return ( \@message );
}

1;
