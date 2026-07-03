package Algorithm::Classifier::NaiveBayes::App;

use 5.006;
use strict;
use warnings;
use App::Cmd::Setup -app;

=head1 NAME

Algorithm::Classifier::NaiveBayes::App - The App::Cmd app class for nb_tool.

=cut

sub global_opt_spec {
	return ( [ 'help|h' => 'This usage screen.' ], );
}

1;
