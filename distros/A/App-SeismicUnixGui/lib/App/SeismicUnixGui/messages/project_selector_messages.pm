package App::SeismicUnixGui::messages::project_selector_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] = (
"Select ONLY one project; then click [OK], (backup_project_selector_message=2)\n"
    );
    return ( \@message );
}

1;

