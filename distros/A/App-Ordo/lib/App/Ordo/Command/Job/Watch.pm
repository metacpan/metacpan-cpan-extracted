package App::Ordo::Command::Job::Watch;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "job watch" }
sub summary { "Monitor an existing process as a job" }
sub usage   { "<name> | --pid <pid> --server <server>" }

sub option_spec {
    return {
        'pid=i'    => 'PID of process to watch',
        'server|s=s' => 'Server where process is running',
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name || ($opt->{pid} && $opt->{server})) {
        say colored(["bold red"], "Usage: job watch <name> OR job watch --pid <pid> --server <server>");
        return;
    }

    my $payload = { server => $opt->{server} };

    if ($name) {
        $payload->{match} = $name;
    } else {
        $payload->{pid} = $opt->{pid};
    }

    my $res = $self->api->call('watch_job', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Now watching " . ($name || "PID $opt->{pid} on $opt->{server}"));
        say "Use 'job logs $name' to view output";
    } else {
        say colored(["bold red"], "Failed to watch job: " . ($res->{message} || 'unknown error'));
    }
}

1;
