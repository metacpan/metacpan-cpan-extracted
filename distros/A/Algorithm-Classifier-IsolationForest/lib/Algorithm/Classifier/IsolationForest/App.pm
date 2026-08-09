package Algorithm::Classifier::IsolationForest::App;

use 5.006;
use strict;
use warnings;
use App::Cmd::Setup -app;

sub global_opt_spec {
	return ( [ 'help|h' => "This usage screen." ], [ 'version|v' => "This usage screen." ], );
}

=head1 NAME

Algorithm::Classifier::IsolationForest::App - the App::Cmd application behind the iforest command

=head1 DESCRIPTION

The L<App::Cmd> application class C<bin/iforest> runs.  Subcommands live
under C<Algorithm::Classifier::IsolationForest::App::Command::> and are
discovered by App::Cmd, so adding a module there adds a command -- there
is no registry to update.

They all inherit from
L<Algorithm::Classifier::IsolationForest::App::Command>, which App::Cmd
also finds by name alone.

=head1 METHODS

=head2 global_opt_spec

The options every subcommand accepts on top of its own, as the list of
arrayrefs L<Getopt::Long::Descriptive> expects.  App::Cmd calls this
while assembling the option spec for whichever command is about to run.

    iforest fit -h        # handled through this spec

=cut

1;
