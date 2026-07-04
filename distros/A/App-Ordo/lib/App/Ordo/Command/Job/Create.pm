package App::Ordo::Command::Job::Create;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);

sub name    { "job create" }
sub summary { "Create a new job" }
sub usage   { "<name> --server <name> --script 'command' [options]" }

sub option_spec {
    return {
        'server=s'           => 'Server to run on (required)',
        'script=s'           => 'Shell command/script (required)',
        'desc=s'             => 'Job description',
        'needs=s@'           => 'Jobs this depends on (AND logic)',
        'needs_any=s@'       => 'Jobs this depends on (OR logic)',
        'retrys=i'           => 'Number of retries',
        'loops=i'            => 'Number of loops',
        'delay=i'            => 'Delay between loops',
        'clonable=i'         => 'Allow cloning',
        'on_fail=i'          => 'Cluster to run on failure',
        'json=s'             => 'Extra JSON data',
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name && $opt->{server} && $opt->{script}) {
        say colored(["bold red"], "Missing required: name, --server, --script");
        $self->show_help;
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
        name        => $name,
        server      => $opt->{server},
        script      => $opt->{script},
        description => $opt->{desc},
        needs       => $opt->{needs} || [],
        needs_any   => $opt->{needs_any} || [],
        retrys      => $opt->{retrys},
        loops       => $opt->{loops},
        delay       => $opt->{delay},
        clonable    => $opt->{clonable},
        on_fail     => $opt->{on_fail},
        json        => $opt->{json},
    };

    my $res = $self->api->call('create_job', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Job '$name' created on server '$opt->{server}'");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
