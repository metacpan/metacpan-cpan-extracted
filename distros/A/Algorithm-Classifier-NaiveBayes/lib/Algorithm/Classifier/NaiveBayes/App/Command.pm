package Algorithm::Classifier::NaiveBayes::App::Command;

use 5.006;
use strict;
use warnings;
use App::Cmd::Setup -command;

=head1 NAME

Algorithm::Classifier::NaiveBayes::App::Command - The base class for nb_tool commands.

=cut

sub opt_spec {
	my ( $class, $app ) = @_;
	return ( [ 'help|h' => 'This usage screen.' ], $class->options($app), );
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;
	if ( $opt->{'help'} ) {
		my ($command) = $self->command_names;
		$self->app->execute_command( $self->app->prepare_command( 'help', $command ) );
		exit;
	}
	$self->validate( $opt, $args );
}

# returns the text to work on, either the remaining args joined by a
# space or stdin slurped
sub text_from {
	my ( $self, $args ) = @_;

	if ( @{$args} ) {
		return join( ' ', @{$args} );
	}

	my $text = do { local $/; <STDIN> };
	return $text;
} ## end sub text_from

1;
