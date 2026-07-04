package App::Ordo::Command::Job::Update;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);

sub name    { "job update" }
sub summary { "Update an existing job" }
sub usage   { "<path/name> [options]" }

sub option_spec {
    return {
        'server|s=s'         => 'Change server',
        'script=s'           => 'Change script',
        'description=s'      => 'Change description',
        'needs=s@'           => 'Replace AND dependencies',
        'needs_any=s@'       => 'Replace OR dependencies',
        'remove_needs'       => 'Remove all dependencies',
        'retrys=i'           => 'Change retry count',
        'loops=i'            => 'Change loop count',
        'delay=i'            => 'Change delay',
        'clonable=i'         => 'Change clonable flag',
        'on_fail=i'          => 'Cluster to run on failure',
        'json=s'             => 'Change JSON data',
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job update <path/name> [options]");
        return;
    }

    my $payload = { name => $name };

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

    # Only include options that were provided
    $payload->{server}      = $opt->{server}      if $opt->{server};
    $payload->{script}      = $opt->{script}      if $opt->{script};
    $payload->{description} = $opt->{description} if $opt->{description};
    $payload->{needs}       = $opt->{needs}       if $opt->{needs};
    $payload->{needs_any}   = $opt->{needs_any}   if $opt->{needs_any};
    $payload->{retrys}      = $opt->{retrys}      if defined $opt->{retrys};
    $payload->{loops}       = $opt->{loops}       if defined $opt->{loops};
    $payload->{delay}       = $opt->{delay}       if defined $opt->{delay};
    $payload->{clonable}    = $opt->{clonable}    if defined $opt->{clonable};
    $payload->{on_fail}     = $opt->{on_fail}     if defined $opt->{on_fail};
    $payload->{json}         = $opt->{json}        if $opt->{json};
    $payload->{remove_needs} = 1 if $opt->{remove_needs};

    unless (keys %$payload > 1) {  # only name
        say colored(["bold yellow"], "No changes specified");
        return;
    }

    my $res = $self->api->call('update_job_config', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Job '$name' updated");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'unknown error'));
    }
}

1;
