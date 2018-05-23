# POD documentation - main docs before the code

=head1 NAME

CLIPSeqTools::App - Main CLIPSeqTools application with tools for analysis of CLIP-Seq libraries.

=head1 SYNOPSIS

CLIPSeqTools::App is the main CLIPSeqTools application with tools for analysis of CLIP-Seq libraries.

=head1 DESCRIPTION

CLIPSeqTools::App consists of tools that employ basic and more advanced
analysis on CLIP-Seq datasets. The offered tools vary from simpler ones
such as the nucletide composition of reads to more complex ones such as
Nmer enrichment within the CLIP-Seq reads.

=head1 EXAMPLES

=cut


package CLIPSeqTools::App;
$CLIPSeqTools::App::VERSION = '0.1.8';

# Make it an App and load plugins
use MooseX::App qw(Config Color BashCompletion Man);


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;


#######################################################################
##########################   Global options   #########################
#######################################################################
option 'verbose' => (
	is            => 'rw',
	isa           => 'Bool',
	cmd_aliases   => 'v',
	default       => 0,
	documentation => 'print progress lines and extra information.',
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub usage_error {
	my ($self, $error_msg) = @_;

	my $class = ref($self) || $self;
	my $meta = $class->meta;

	MooseX::App::Message::Envelope->new(
		$meta->command_message(
			header          => $error_msg,
			type            => "error",
		),
		$meta->command_usage_command($meta),
	)->run;

	exit 1;
}

1;
