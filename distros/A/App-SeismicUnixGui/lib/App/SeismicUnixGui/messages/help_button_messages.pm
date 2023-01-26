package App::SeismicUnixGui::messages::help_button_messages;

use Moose;
our $VERSION = '0.0.1';

my $help_button_messages = {
	
	_item => 'About', # default

};

sub get {
	my ($self) = @_;

	if ( length $help_button_messages->{_item} ) {
		
		my $item = $help_button_messages->{_item};
		my $pathNmodule_pm = '../messages' . '/' . $item;
#		print("L_SU,help_menubutton,$pathNmodule_pm \n");
		system("tkpod $pathNmodule_pm &\n\n");

	}
	else {
		print("help_button_messages, missing item\n");
	}

	return ();
}


sub set {
	my ($self, $item) = @_;

	if ( length $item ) {

       $help_button_messages->{_item} = $item;

	}
	else {
		print("help_button_messages, missing item\n");
	}

	return ();
}

1;

