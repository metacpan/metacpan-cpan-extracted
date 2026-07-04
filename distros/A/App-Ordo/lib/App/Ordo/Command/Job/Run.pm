package App::Ordo::Command::Job::Run;
use Moo;
use feature qw(say);
use Term::ANSIColor qw(colored);

extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);

sub name    { "job run" }
sub summary { "Run a job immediately" }
sub usage   { "<path/name>" }
sub aliases { ['job start'] }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job run <path/name>");
        return;
    }

    my $res = $self->api->call('start_job', { name => $name });

    if ($res->{success}) {
        say colored(["bold green"], "Job started");
    } else {
        say colored(["bold red"], "Failed to start job: " . ($res->{message} || 'not found'));
    }
}

1;
