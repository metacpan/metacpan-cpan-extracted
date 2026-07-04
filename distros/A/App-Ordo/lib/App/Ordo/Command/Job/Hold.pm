# Example: lib/App/Ordo/Command/Job/Hold.pm
package App::Ordo::Command::Job::Hold;
use feature qw(say);
use Moo;
extends 'App::Ordo::Command::Base';
use Term::ANSIColor qw(colored);

sub name    { "job hold" }
sub summary { "Pause a job from running" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;
    unless ($name) {
        say colored(["bold red"], "Usage: job hold <path/name>");
        return;
    }

    my $res = $self->api->call('hold_job', { name => $name });

    $res->{success}
        ? say colored(["bold yellow"], "Job '$name' held")
        : say colored(["bold red"], "Failed: " . ($res->{message} || 'error'));
}

1;
