package App::Ordo::Command::Job::Log;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "job log" }
sub summary { "Show job output - latest run if no ID given" }
sub usage   { "<path/name> [log-id]" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name, $log_id) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job log <path/name> [log-id]");
        say "  Omit log-id to see the most recent run";
        return;
    }

    my $payload = { name => $name };
    $payload->{log_id} = $log_id if defined $log_id && $log_id =~ /^\d+$/;

    my $res = $self->api->call('read_log', $payload);

    unless ($res->{success} && defined $res->{out}) {
        say colored(["bold red"], "No log found for '$name'" . ($log_id ? " (run $log_id)" : ""));
        say $res->{message} if $res->{message};
        return;
    }

    my $which = $log_id ? "run $log_id" : "most recent run";
    print $res->{out};
}

1;

