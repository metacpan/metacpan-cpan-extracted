package Algorithm::Classifier::IsolationForest::App::Command;
use App::Cmd::Setup -command;

sub global_opt_spec {
        my ( $class, $app ) = @_;
        return (
                $class->options($app),
        );
} ## end sub global_opt_spec

sub validate_args {
        my ( $self, $opt, $args ) = @_;
        if ( $opt->{help} ) {
                my ($command) = $self->command_names;
                $self->app->execute_command( $self->app->prepare_command( "help", $command ) );
                exit;
        }
        $self->validate( $opt, $args );
}

return 1;
