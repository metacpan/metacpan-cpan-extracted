package App::Ordo::Command::Job::Kill;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "job kill" }
sub summary { "Kill a running job" }
sub usage   { "<name>" }

sub option_spec {
    return {};
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job kill <name>");
        return;
    }

    my $payload = { name => $name };

    my $res = $self->api->call('kill_job', $payload);

    if ($res->{success}) {
        say colored(["bold yellow"], "Job '$name' killed");
    } else {
        say colored(["bold red"], "Failed to kill job: " . ($res->{message} || 'unknown error'));
    }
}

1;
