package App::SeismicUnixGui::messages::color_listbox_messages;

use Moose;
our $VERSION = '0.0.1';

sub get {
    my ( $self) = @_;
    my @message;

$message[0] = ("Warning:  You are about to overwrite a flow \n
Are you sure?

	(color_listbox_message=0)\n");
	
    return ( \@message );
}

1;
