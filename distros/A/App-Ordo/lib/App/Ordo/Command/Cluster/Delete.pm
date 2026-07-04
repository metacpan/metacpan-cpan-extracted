package App::Ordo::Command::Cluster::Delete;
use Moo;
use feature qw(say);
use Term::ANSIColor qw(colored);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);

sub name    { "cluster delete" }
sub summary { "Delete a cluster and all its jobs" }
sub usage   { "<path>" }

sub option_spec {
    return {
        'force|f' => 'Force delete even if jobs are running',
    };
}

sub execute {
    my ($self, $opt, $path) = @_;

    unless ($path) {
        say colored(["bold red"], "Usage: cluster delete <path> [--force]");
        return;
    }

    #my $full_path = $path =~ m|^/| ? $path : "$CURRENT_PATH/$path";
    #$full_path =~ s|//+|/|g;

    my $payload = { name => $path };
    $payload->{force} = 1 if $opt->{force};

    my $res = $self->api->call('delete_cluster', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Cluster and all jobs deleted");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
        say "Hint: use --force if jobs are running" if $res->{message} && $res->{message} =~ /running|active/i;
    }
}

1;
