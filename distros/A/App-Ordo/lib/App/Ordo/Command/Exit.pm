package App::Ordo::Command::Exit;
use Moo;
extends 'App::Ordo::Command::Base';

sub name    { "exit" }
sub summary { "Exit the interactive shell" }
sub usage   { "" }
sub aliases { ['quit'] }

sub option_spec { {} }

sub execute {
    my ($self) = @_;
    say colored(["bold yellow"], "Goodbye!");
    exit 0;
}

1;
