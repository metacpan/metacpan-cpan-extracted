package App::SeismicUnixGui::messages::flows_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] = (
"Warning: Second item is not allowed. Use data_out   (flows_message=0)\n"
    );
    $message[1] = (
"Warning: First item is not allowed. Use another program. (flows_message=1)\n"
    );

    $message[2] = (
        "Warning: Last item is not allowed. Use data_out    (flows_message=2)\n"
    );
    $message[3] = (
        "Warning: First or second items are not allowed.    (flows_message=3)\n"
    );
    $message[4] =
        "Only one item in flow--flow may not run: 		   (flows, set_specs)"
      . "\n"
      . "e.g., unif2 may run but not suximage";
    $message[5] =
      ("No items in flow--flow will not run: 		       (flows, set_specs)\n");

    return ( \@message );
}

1;
