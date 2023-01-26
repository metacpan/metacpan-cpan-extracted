package App::SeismicUnixGui::messages::superflow_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] = (
"Warning: No Project exists. Go back and create one using Project Selector (superflow_messages = 0)\n"
    );

    $message[1] = (
"Warning: Not a simple flow. Try using \'Save\' for Tools. (superflow_messages = 1 )\n"
    );

    return ( \@message );
}

1;
