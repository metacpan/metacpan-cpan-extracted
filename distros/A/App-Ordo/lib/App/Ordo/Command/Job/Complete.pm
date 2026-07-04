package App::Ordo::Command::Job::Complete;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';
use open ':std', ':utf8';


use Term::ANSIColor qw(colored);

sub name    { "job complete" }
sub summary { "Force a job to complete state (triggers dependents)" }
sub usage   { "<name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job complete <name>");
        return;
    }

    my $res = $self->api->call('complete_job', { name => $name });

    if ($res->{success}) {
        say colored(["bold green"], "Job '$name' marked complete - dependents may now run");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
