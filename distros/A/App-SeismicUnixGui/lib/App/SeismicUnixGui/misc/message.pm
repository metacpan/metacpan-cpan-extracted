package App::SeismicUnixGui::misc::message;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: message 
 AUTHOR:  Juan Lorenzo
 DATE:   July 25 2015
 DESCRIPTION: 
 Version: 0.0.1

=head2 USE

=head3 NOTES
 communicate information to user 

=head4 
 Examples

=head3 UNIX NOTES  
=head4 CHANGES and their DATES
V0.0.2 April 4, 2020


=cut

=head2 Declare
Modules

=cut

use Moose;
our $VERSION = '0.0.2';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
#use namespace::autoclean;    # best-practices hygiene
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 Instantiation

=cut

my $Project     = Project_config->new();
my $get         = L_SU_global_constants->new();

=head2 Declare
local variables

=cut

my $var                 = $get->var();
my $log_file_txt        = $var->{_log_file_txt};
my $test_dir_name 		= $var->{_test_dir_name};
my $PL_SEISMIC          = $Project->PL_SEISMIC();

=head2 Defaults

=cut

my $PATH_start               = 	$PL_SEISMIC;
my $file_name_start          = $log_file_txt;
my $number_of_messages_start = 2;
my $message_start            = 'hi';

=head2 sub default_message_aref

Initialize array 

=cut

sub _default_message_aref_start {

	my ($self) = @_;

	my @message = (
		$message_start,
		$message_start,
	);

	my $message_aref = \@message;
	return ($message_aref);

}

=head2 private anonymous array

=cut

my $message = {
	_text         => '',
	_this_package => '',

};

sub BUILD {
	my ($this_package_address) = @_;

	$message->{_this_package} = $this_package_address;

}

=head2 Declare attributes

=cut

has 'PATH' => (
	default => $PATH_start,
	is      => 'rw',
	isa     => 'Str',
	writer  => 'set_PATH',
	reader  => 'get_PATH',

	#	trigger => \&_update_PATH,
);

=head2 Declare attributes

=cut

has 'file_name' => (
	default => $file_name_start,
	is      => 'rw',
	isa     => 'Str',
	writer  => 'set_file_name',
	reader  => 'get_file_name',
	trigger => \&_update_file_name,
);

=head2 Declare attributes

=cut

has 'message_aref' => (
	default => \&_default_message_aref_start,
	is      => 'rw',
	isa     => 'ArrayRef',
	writer  => 'set_message_aref',
	reader  => 'get_message_aref',

	#	trigger=> \&_update_message_aref,
);

has 'number_of_messages' => (
	default => $number_of_messages_start,
	is      => 'rw',
	isa     => 'Int',
	writer  => 'set_number_of_messages',
	reader  => 'get_number_of_messages',

	#	trigger=> \&_update_number_of_messages,
);

=head2 sub _update_file_name

update file_name

=cut

sub _update_file_name {

	my ( $message, $new_current_file_name, $new_prior_file_name ) = @_;

	my $ans = $message->get_file_name();

#	print("message,_file_name,file_name= $ans  NADA \n");

	return ();

}

=head2 sub _update_message_aref

update message_aref

=cut

sub _update_message_aref {

	my ( $message, $new_current_message_aref, $new_prior_message_aref ) = @_;

	my @ans = @{$new_current_message_aref};

	#    my @ans = @{$new_prior_message_aref};

	#	print("1. message,_update_message_aref,message_aref= @ans  \n");

	@ans = @{ $message->get_message_aref() };
	print("2. message,_update_message_aref,message_aref= @ans  \n");

	return ();
}

=head2 sub _update_number_of_messages

update file_name

=cut

sub _update_number_of_messages {

	my ( $message, $new_current_number_of_messages, $new_prior_number_of_messages ) = @_;

	my $ans = $message->get_number_of_messages();

	print("message,_update_number_of_messages, number_of_messages= $ans  \n");

	return ();

}

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
	$message->{_text} = '';
}

=head2 subroutine command_line
Send message to command_line 

=cut

sub command_line {
	my ($self) = @_;

	my $message = $message->{_this_package};

	if ( length( $message->{number_of_messages} ) ) {

		my $number_of_messages = $message->{number_of_messages};
		my @message            = @{ $message->get_message_aref() };

		for ( my $i = 0; $i < $number_of_messages; $i++ ) {

			if ( length( $message[$i] ) ) {

				print("$message[$i]\n");

			} else {
				print("message,command_line, empty message\n");
			}
		}

	} else {
		print("message,command_line, no messages to print\n");
		my $ans = $message->{number_of_messages};
		print("message,command_line, number_of_messages=$ans\n");
	}

}


=head2 subroutine file 

 send message to file 

=cut

sub file {
	my ( $message, $text ) = @_;
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                            localtime(time);

	$message->{_text} = $text if defined($text);
	my $PATH    = $message->get_PATH();
	my $PATH_n_file = $PATH . '/' . $log_file_txt;
#	print("\nmessage, file, PATH_n_file=$PATH_n_file\n");

	open( message_STDOUT, '>>', $PATH_n_file ) or die $!;
	print message_STDOUT $text . "\n\n";
	close(message_STDOUT);
}

=head2 subroutine file_name 

 send message to file_name 

=cut

sub send2file_name {
	my ($self) = @_;

	my $message = $message->{_this_package};
	my $PATH    = $message->get_PATH();

	if (   length $PATH
		&& length ($message->get_file_name()) ) {

		my $PATH_n_file = $PATH.'/' . $message->get_file_name();
		my $text        = @{ $message->get_message_aref() }[0];
		my $send2file_name = $message->get_file_name();
		
#		print("message, send2file_name, PATH=$PATH\n");
#		print("message, send2file_name, PATH_n_file=$PATH_n_file\n");
#		print("message, send2file_name, send2file_name=$send2file_name\n");
		
		open( message_STDOUT, '>>', $PATH_n_file ) or die $!;
		print message_STDOUT $text . "\n";
		close(message_STDOUT);

	} else {
		print("message,send2file_name, missing value(s)\n");
	}

}

=head2 subroutine screen

 send message to screen 

=cut

sub screen {
	my ( $message, $text ) = @_;

	$message->{_text} = $text if defined($text);
	print ("message,screen:\n$text\n\n");
}



=head2 subroutine time 

 send time to file 

=cut

sub time {
	my ($message) = @_;
	
    my $text = localtime;

	my $PATH    = $message->get_PATH();
	my $PATH_n_file = $PATH . '/' . $log_file_txt;
#	print("\nmessage, file, PATH_n_file=$PATH_n_file\n");

	open( message_STDOUT, '>>', $PATH_n_file ) or die $!;
	print message_STDOUT $text . "\n\n";
	close(message_STDOUT);

}

# a 1 is sent to perl to signify the end of the package
1;
