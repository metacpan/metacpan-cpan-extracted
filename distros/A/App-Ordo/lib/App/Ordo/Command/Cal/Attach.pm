package App::Ordo::Command::Cal::Attach;
use Moo;
use Term::ANSIColor qw(colored);
use feature qw(say);
extends 'App::Ordo::Command::Base';

sub name    { "cal attach" }
sub summary { "Attach a calendar to a cluster" }
sub usage   { "<calendar> <cluster-path>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $cal_name, $cluster_path) = @_;

    unless ($cal_name && $cluster_path) {
        say colored(["bold red"], "Usage: cal attach <calendar> <cluster-path>");
        return;
    }

    my $res = $self->api->call('update_cluster', {
        name   => $cluster_path,
        cal    => $cal_name,        # server accepts 'cal' => name
    });

    if ($res->{success}) {
        say colored(["bold green"], "Calendar '$cal_name' attached to cluster '$cluster_path'");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'not found'));
    }
}

1;
