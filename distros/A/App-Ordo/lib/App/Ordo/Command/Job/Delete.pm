package App::Ordo::Command::Job::Delete;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);

sub name    { "job delete" }
sub summary { "Delete a job" }
sub usage   { "<path/name>" }
sub aliases { ['job rm'] }

sub option_spec {
    return {
        'force|f' => 'Force delete even if running',
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job delete <path/name> [--force]");
        return;
    }

    my $payload = { name => $name };
    $payload->{force} = 1 if $opt->{force};

    my $res = $self->api->call('delete_job', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Job '$name' deleted");
    } else {
        my $msg = $res->{message} || 'unknown error';
        say colored(["bold red"], "Failed to delete job: $msg");
        say "Try --force if the job is running" if $msg =~ /running/i;
    }
}

1;
