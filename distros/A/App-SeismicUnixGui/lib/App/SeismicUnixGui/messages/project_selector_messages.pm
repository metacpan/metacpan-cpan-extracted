package App::SeismicUnixGui::messages::project_selector_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

    $message[0] = (
"Warning:  Choose only one project. Only one box can be green. (project_selector_message=0)\n"
    );
    $message[1] = (
"Warning:  A project with that name exists already [PROJECT_HOME]. Try again (project_selector_message=1)\n"
    );
    $message[2] = (
"Create New project or select an old one; then click [OK], (project_selector_message=2)\n"
    );
    return ( \@message );
}

1;

