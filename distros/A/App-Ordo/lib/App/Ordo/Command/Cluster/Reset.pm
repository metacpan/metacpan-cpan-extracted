package App::Ordo::Command::Cluster::Reset;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cluster reset" }
sub summary { "Reset cluster and all jobs to ready state" }
sub usage   { "<path>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $path) = @_;

    unless ($path) {
        say colored(["bold red"], "Usage: cluster reset <path>");
        return;
    }

    my $res = $self->api->call('reset_cluster', { name => $path });

    if ($res->{success}) {
        say colored(["bold cyan"], "Cluster '$path' and all jobs reset to ready");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
