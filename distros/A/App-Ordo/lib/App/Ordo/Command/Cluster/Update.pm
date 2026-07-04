package App::Ordo::Command::Cluster::Update;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);

sub name    { "cluster update" }
sub summary { "Update an existing cluster" }
sub usage   { "<path> [options]" }

sub option_spec {
    return {
        'description=s'         => 'Change description',
        'needs=s@'              => 'Replace AND dependencies',
        'needs_any=s@'          => 'Replace OR dependencies',
        'remove_needs'          => 'Remove all dependencies (boolean)',
        'cal=s'                 => 'Attach/detach calendar (name or empty)',
        'loops=i'               => 'Change loop count',
        'clonable=i'            => 'Change clonable flag',
        'on_fail=s'             => 'Change fail alarm cluster',
    };
}

sub execute {
    my ($self, $opt, $path) = @_;

    unless ($path) {
        say colored(["bold red"], "Usage: cluster update <path> [options]");
        return;
    }

    my $payload = { name => $path };

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

    # Only include provided options
    $payload->{description} = $opt->{description} if $opt->{description};
    $payload->{needs}       = $opt->{needs}       if $opt->{needs};
    $payload->{needs_any}   = $opt->{needs_any}   if $opt->{needs_any};
    $payload->{remove_needs} = $opt->{remove_needs} if $opt->{remove_needs};
    $payload->{cal}         = $opt->{cal}         if exists $opt->{cal};
    $payload->{loops}       = $opt->{loops}       if defined $opt->{loops};
    $payload->{clonable}    = $opt->{clonable}    if defined $opt->{clonable};
    $payload->{on_fail}     = $opt->{on_fail}     if $opt->{on_fail};

    unless (keys %$payload > 1) {
        say colored(["bold yellow"], "No changes specified");
        return;
    }

    my $res = $self->api->call('update_cluster', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Cluster '$path' updated");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
