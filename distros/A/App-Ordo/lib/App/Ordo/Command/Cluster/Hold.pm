package App::Ordo::Command::Cluster::Hold;
use feature qw(say);
use Moo;
extends 'App::Ordo::Command::Base';
use Term::ANSIColor        qw(colored);

sub name    { "cluster hold" }
sub summary { "Prevent cluster from running" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;
    unless ($name) {
        say colored(["bold red"], "Usage: cluster hold <path/name>");
        return;
    }

    my $res = $self->api->call('hold_cluster', { name => $name });

    $res->{success}
        ? say colored(["bold yellow"], "Cluster '$name' held")
        : say colored(["bold red"], "Failed: " . ($res->{message} || 'error'));
}

1;
