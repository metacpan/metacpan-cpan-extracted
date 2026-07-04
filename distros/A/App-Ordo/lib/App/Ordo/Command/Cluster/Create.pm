package App::Ordo::Command::Cluster::Create;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);

sub name    { "cluster create" }
sub summary { "Create a new cluster (folder/DAG)" }
sub usage   { "<path> [options]" }

sub option_spec {
    return {
        #'desc|description|d=s'  => 'Cluster description',
        'desc'                  => 'Cluster description',
        'needs=s@'              => 'Clusters this depends on (AND logic)',
        'needs_any=s@'          => 'Clusters this depends on (OR logic)',
        'cal=s'                 => 'Attach calendar by name',
        'loops=i'               => 'Number of loops',
        'clonable=i'            => 'Allow cloning (0/1)',
        'on_fail=s'             => 'Cluster to run on failure',
    };
}

sub execute {
    my ($self, $opt, $path) = @_;

    unless ($path) {
        say colored(["bold red"], "Usage: cluster create <path> [options]");
        return;
    }

    if ($opt->{needs}) {
        my @expanded;
        for my $item (@{$opt->{needs}}) {
            push @expanded, split /,/, $item;
        }
        $opt->{needs} = \@expanded;
    }

    if ($opt->{needs_any}) {
        my @expanded;
        for my $item (@{$opt->{needs_any}}) {
            push @expanded, split /,/, $item;
        }
        $opt->{needs_any} = \@expanded;
    }

    my $payload = {
        name        => $path,
        description => $opt->{desc},
        needs       => $opt->{needs} || [],
        needs_any   => $opt->{needs_any} || [],
        cal         => $opt->{cal},
        loops       => $opt->{loops},
        clonable    => $opt->{clonable},
        on_fail     => $opt->{on_fail},
    };

    my $res = $self->api->call('create_cluster', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Cluster '$path' created");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
