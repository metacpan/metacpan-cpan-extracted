package App::Ordo::Command::Cluster::Complete;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';
use open ':std', ':utf8'; 

use Term::ANSIColor qw(colored);

sub name    { "cluster complete" }
sub summary { "Force a cluster and all jobs to complete state" }
sub usage   { "<path>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $path) = @_;

    unless ($path) {
        say colored(["bold red"], "Usage: cluster complete <path>");
        return;
    }

    my $res = $self->api->call('complete_cluster', { name => $path });

    if ($res->{success}) {
        say colored(["bold green"], "Cluster '$path' marked complete - dependent clusters may now run");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
