package App::SeismicUnixGui::messages::help_button_messages;

use Moose;
our $VERSION = '0.0.2';

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: help_button_messages.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017 

 DESCRIPTION 
     

 BASED ON:

 
=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head2 CHANGES and their DATE

 V 0.2.0 April 2023 Introduce viewing of pdf files

=cut 

=head2 Notes from bash
 
=cut 

my $path4SeismicUnixGui;

BEGIN {

	my $starting_point = '/';
	my $path2find      = "*/App/SeismicUnixGui/script";
	my $fifo           = 'tbd';

	if ( length $ENV{'SeismicUnixGui'} ) {

		$path4SeismicUnixGui = $ENV{'SeismicUnixGui'};

	}
	else {
# When environment variables can not be found in Perl
#	system(
#" echo \"find $starting_point -path \'$path2find\' -print 2>/dev/null > $fifo \" "
#	);
		system(
"find $starting_point -path \'$path2find\' -print > $fifo 2>/dev/null & "
		);

		# wait around until the file is populated with something inside
		while ( !( -e $fifo )
			or ( -e $fifo and -z $fifo ) )
		{
			#			print "waiting...\n";
		}

		# read file contents
		open my $fh, "<", $fifo or die "Can not open '$fifo': $!";

		chomp( my @script_list = <$fh> );

		close $fh;

		$path4SeismicUnixGui = $script_list[0] . '/..';
		print(
"\nL24. Warning: Using default, help_button_messages, L_SU = $path4SeismicUnixGui\n"
		);

	}

}

my $help_button_messages = {

	_About => 'About',    # default
	_item  => 'item',

};

my sub clear {

	$help_button_messages->{_About} = '';
	$help_button_messages->{_item}  = '';

}

sub get {
	my ($self) = @_;

	if ( length $help_button_messages->{_About} ) {

		my $item           = $help_button_messages->{_About};
		my $pathNmodule_pm = '../messages' . '/' . $item;

		#		print("L_SU,help_menubutton,$pathNmodule_pm \n");
		system("tkpod $pathNmodule_pm &\n\n");

	}
	else {
		print("help_button_messages, missing item\n");
	}

	return ();
}

sub get_pdf {
	my ($self) = @_;

	if ( length $help_button_messages->{_item} ) {

		my $inbound_pdf =
		  $path4SeismicUnixGui . '/doc/' . $help_button_messages->{_item};

#		print("help_button_messages,get_pdf, $inbound_pdf\n");
		system("evince $inbound_pdf &");

	}
	else {
		print("help_button_messages, missing item\n");
	}

	return ();
}

sub set {
	my ( $self, $item ) = @_;

	if ( length $item ) {

		$help_button_messages->{_item} = $item;

	}
	else {
		print("help_button_messages, missing item\n");
	}

	return ();
}

sub set_pdf {
	my ( $self, $item ) = @_;

	if ( length $item ) {

		if ( $item eq 'InstallationGuide' ) {

			$help_button_messages->{_item} =
			  'SeismicUnixGuiInstallationGuide0.87.3.pdf';

		}
		elsif ( $item eq 'Tutorial' ) {

			$help_button_messages->{_item} =
			  'SeismicUnixGuiTutorial0.87.3.pdf';
			
			
		} else{
			print("help_button_messages, set_pdf, unexpectedly here\n");
			print("help_button_messages, set_pdf, not ready for $item\n");
		}

	}
	else {
		print("help_button_messages, set_pdf, missing item\n");
	}

	return ();
}

1;

