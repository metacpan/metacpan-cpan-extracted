package App::Ordo::Command::Cluster::Kill;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cluster kill" }
sub summary { "Kill all running jobs in a cluster" }
sub usage   { "<path>" }

sub option_spec {
    return {};
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: cluster kill <path>");
        return;
    }

    my $payload = { name => $name };

    my $res = $self->api->call('kill_cluster', $payload);

    if ($res->{success}) {
        say colored(["bold yellow"], "All running jobs in cluster '$name' killed");
    } else {
        say colored(["bold red"], "Failed to kill cluster: " . ($res->{message} || 'unknown error'));
    }
}

1;
