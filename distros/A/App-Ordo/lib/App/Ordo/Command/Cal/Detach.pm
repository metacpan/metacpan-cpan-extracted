package App::Ordo::Command::Cal::Detach;
use Moo;
use Term::ANSIColor qw(colored);
use feature qw(say);
extends 'App::Ordo::Command::Base';

sub name    { "cal detach" }
sub summary { "Detach a calendar from a cluster" }
sub usage   { "<calendar> <cluster-path>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $cal_name, $cluster_path) = @_;

    unless ($cal_name && $cluster_path) {
        say colored(["bold red"], "Usage: cal detach <calendar> <cluster-path>");
        return;
    }

    my $res = $self->api->call('update_cluster', {
        name   => $cluster_path,
        cal_id => '',               # empty string = detach
    });

    if ($res->{success}) {
        say colored(["bold green"], "Calendar '$cal_name' detached from cluster '$cluster_path'");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'not found'));
    }
}

1;
