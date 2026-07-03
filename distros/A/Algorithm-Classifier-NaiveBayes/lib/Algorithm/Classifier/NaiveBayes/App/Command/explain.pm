package Algorithm::Classifier::NaiveBayes::App::Command::explain;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;
use JSON::PP ();

sub options {
	return (
		[ 'm=s',  'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ],
		[ 'json', 'Print the raw explanation as JSON instead.' ],
	);
}

sub abstract { 'Classify the specified text and explain why' }

sub description {
	return 'Classify the specified text and show which tokens pushed it towards the class.

The text is taken from the remaining args joined by a space, or from
stdin if no args are given. Prints the class, its probability, and
every token sorted by how hard it pushed towards the winning class
over the runner up.

    nb_tool explain -m model.json you have won a free cruise
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}

	return 1;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb = Algorithm::Classifier::NaiveBayes->new;
	$nb->load( $opt->{'m'} );

	my $explanation = $nb->explain( $self->text_from($args) );
	if ( !defined($explanation) ) {
		die('The model has not been trained yet');
	}

	if ( $opt->{'json'} ) {
		print JSON::PP->new->canonical->pretty->encode($explanation);
		return;
	}

	my $class = $explanation->{'class'};
	print $class. ', probability ' . sprintf( '%.3f', $explanation->{'probs'}{$class} ) . "\n";

	my ( $first, $second )
		= sort { $explanation->{'scores'}{$b} <=> $explanation->{'scores'}{$a} } keys %{ $explanation->{'scores'} };
	if ( !defined($second) ) {
		return;
	}

	my %pull;
	foreach my $token ( keys %{ $explanation->{'tokens'} } ) {
		my $contribs = $explanation->{'tokens'}{$token}{'contributions'};
		$pull{$token} = ( $contribs->{$first} - $contribs->{$second} ) * $explanation->{'tokens'}{$token}{'count'};
	}
	foreach my $token ( sort { $pull{$b} <=> $pull{$a} } keys %pull ) {
		my $towards = $pull{$token} > 0 ? $first : $second;
		print '    ' . $token . ' pushed towards ' . $towards . ' by ' . sprintf( '%.3f', abs( $pull{$token} ) ) . "\n";
	}
} ## end sub execute

1;
