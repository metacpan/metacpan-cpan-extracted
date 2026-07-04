package App::Ordo::Command::Cluster::Release;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';
use Term::ANSIColor        qw(colored);

sub name    { "cluster release" }
sub summary { "Release a held cluster" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;
    unless ($name) {
        say colored(["bold red"], "Usage: release hold <path/name>");
        return;
    }

    my $res = $self->api->call('release_cluster', { name => $name });

    $res->{success}
        ? say colored(["bold yellow"], "Cluster '$name' released")
        : say colored(["bold red"], "Failed: " . ($res->{message} || 'error'));
}

1;
