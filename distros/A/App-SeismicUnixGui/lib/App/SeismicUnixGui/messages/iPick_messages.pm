package App::SeismicUnixGui::messages::iPick_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] = (
"Geopsy directories missing. Save, then Run: Tools->Project with geopsy=yes (iPick_message=0)\n"
    );
    $message[1] = ("Warning:   (iPick_message=1)\n");

    return ( \@message );
}

1;

