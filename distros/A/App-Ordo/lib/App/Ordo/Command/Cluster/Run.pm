package App::Ordo::Command::Cluster::Run;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';
use Term::ANSIColor qw(colored);

use App::Ordo qw($CURRENT_PATH);

sub name    { "cluster run" }
sub summary { "Run all jobs in a cluster (in dependency order)" }
sub usage   { "<path>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $path) = @_;

    #unless ($path) {
    #    say colored(["bold red"], "Usage: cluster run <path>");
    #    return;
    #}

    my $res = $self->api->call('start_cluster', { name => $path });

    if ($res->{success}) {
        say colored(["bold green"], "Cluster started");
    } else {
        say colored(["bold red"], "Failed to start cluster: " . ($res->{message} || 'not found'));
    }
}

1;
