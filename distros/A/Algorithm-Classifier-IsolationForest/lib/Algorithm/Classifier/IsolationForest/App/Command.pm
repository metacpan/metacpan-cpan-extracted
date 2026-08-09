package Algorithm::Classifier::IsolationForest::App::Command;
use strict;
use warnings;
use App::Cmd::Setup -command;

sub global_opt_spec {
	my ( $class, $app ) = @_;
	return ( $class->options($app), );
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;
	if ( $opt->{help} ) {
		my ($command) = $self->command_names;
		$self->app->execute_command( $self->app->prepare_command( "help", $command ) );
		exit;
	}
	$self->validate( $opt, $args );
}

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command - base class for the iforest subcommands

=head1 DESCRIPTION

Every C<iforest> subcommand inherits from this.  L<App::Cmd> finds it by
name alone -- L<Algorithm::Classifier::IsolationForest::App>'s C<-app>
setup looks for C<< <app class>::Command >> -- so the command modules
never mention it.

It earns its keep through L</validate_args>, which makes C<-h> print a
command's help instead of being validated like any other flag.

=head1 METHODS

=head2 global_opt_spec

Option-spec hook delegating to an C<options> method on the command,
taking the L<App::Cmd> application object and returning whatever that
method returns.

Nothing reaches this in practice: App::Cmd calls C<global_opt_spec> on
the application class rather than on the command base, and no command
here defines C<options> -- they all use App::Cmd's own C<opt_spec>.
Calling it would die on the missing method.

=head2 validate_args

App::Cmd's per-command validation hook, wrapped so C<-h> short-circuits
it.  Without this, C<-h> would fall through to the command's own
C<validate> and trip over whatever required options the user has not
typed yet -- which is exactly the moment they are reaching for the help.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns whatever the command's C<validate> returns.  Under
C<-h> it does not return at all: the help command runs and the process
exits.

    iforest predict -h        # prints predict's help, exits

=cut

return 1;
