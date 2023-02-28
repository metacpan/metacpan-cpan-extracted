package App::SeismicUnixGui::messages::FileDialog_close_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] =
      ("Warning: Only Tools allowed (FileDialog_close_messages = 0)\n");
    $message[1] =
      ("Warning: Perl flows not supported (FileDialog_close_messages = 1)\n");
    $message[2] = (
"Warning: Pick Choose instead of View (FileDialog_close_messages = 2))\n"
    );

    return ( \@message );
}

1;

