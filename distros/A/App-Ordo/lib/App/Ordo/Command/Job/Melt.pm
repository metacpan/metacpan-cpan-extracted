package App::Ordo::Command::Job::Melt;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "job melt" }
sub summary { "Unfreeze a job previously iced" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job melt <path/name>");
        return;
    }

    my $res = $self->api->call('melt_job', { name => $name });

    if ($res->{success}) {
        say colored(["bold green"], "Job '$name' melted");
    } else {
        say colored(["bold red"], "Failed to melt job: " . ($res->{message} || 'error'));
    }
}

1;
