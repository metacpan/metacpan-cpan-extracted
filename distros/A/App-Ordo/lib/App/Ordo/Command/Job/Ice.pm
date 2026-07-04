package App::Ordo::Command::Job::Ice;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "job ice" }
sub summary { "Skip job without blocking dependents" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job ice <path/name>");
        return;
    }

    my $res = $self->api->call('ice_job', { name => $name });

    if ($res->{success}) {
        say colored(["bold cyan"], "Job '$name' iced");
        say colored(["bright_black"], "Downstream jobs will run as soon as upstream complete");
    } else {
        say colored(["bold red"], "Failed to ice job: " . ($res->{message} || 'error'));
    }
}

1;
