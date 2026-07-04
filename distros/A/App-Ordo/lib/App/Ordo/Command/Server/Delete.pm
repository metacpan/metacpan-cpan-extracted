package App::Ordo::Command::Server::Delete;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "server delete" }
sub summary { "Remove a worker server" }
sub usage   { "<name>" }
sub aliases { ['server rm'] }

sub option_spec {
    return {
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: server delete <name> [--force]");
        return;
    }

    my $payload = { name => $name };
    $payload->{force} = 1 if $opt->{force};

    my $res = $self->api->call('delete_monitor', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Server '$name' deleted");
    } else {
        say colored(["bold red"], "Failed to delete server: " . ($res->{message} || 'unknown error'));
        say "Hint: use --force if jobs are still running on it" if $res->{message} && $res->{message} =~ /running|active/i;
    }
}

1;
