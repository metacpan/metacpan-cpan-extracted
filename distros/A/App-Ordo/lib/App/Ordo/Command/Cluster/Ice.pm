package App::Ordo::Command::Cluster::Ice;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cluster ice" }
sub summary { "Skip cluster without blocking dependents" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: cluster ice <path/name>");
        return;
    }

    my $res = $self->api->call('ice_cluster', { name => $name });

    if ($res->{success}) {
        say colored(["bold cyan"], "Cluster '$name' iced - will be skipped");
        say colored(["bright_black"], "Downstream clusters will run as soon as upstream complete");
    } else {
        say colored(["bold red"], "Failed to ice cluster: " . ($res->{message} || 'error'));
    }
}

1;
