package App::Ordo::Command::Job::Release;
use Moo;
extends 'App::Ordo::Command::Base';
use feature qw(say);
use Term::ANSIColor qw(colored);

sub name    { "job release" }
sub summary { "Release a held job" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;
    unless ($name) {
        say colored(["bold red"], "Usage: release hold <path/name>");
        return;
    }

    my $res = $self->api->call('release_job', { name => $name });

    $res->{success}
        ? say colored(["bold yellow"], "Cluster '$name' held")
        : say colored(["bold red"], "Failed: " . ($res->{message} || 'error'));
}

1;
