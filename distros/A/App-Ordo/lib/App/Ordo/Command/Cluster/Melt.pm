package App::Ordo::Command::Cluster::Melt;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cluster melt" }
sub summary { "Unfreeze a cluster previously iced" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: cluster melt <path/name>");
        return;
    }

    my $res = $self->api->call('melt_cluster', { name => $name });

    if ($res->{success}) {
        say colored(["bold green"], "Cluster '$name' melted — back in rotation");
    } else {
        say colored(["bold red"], "Failed to melt cluster: " . ($res->{message} || 'error'));
    }
}

1;
