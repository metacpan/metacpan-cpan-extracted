package App::SeismicUnixGui::messages::save_button_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] = (
"Warning:  Flow is unchanged. Activate flow by clicking inside parameter box  (save_button_message=0)\n"
    );
    $message[1] = (
"Warning:  Needs output file name. Use File/SaveAs. (save_button_message=1)\n"
    );

    return ( \@message );
}

1;

