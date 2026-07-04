package App::Ordo::Command::Cluster::Show;
use Moo;
use feature qw(say);
use POSIX qw(strftime);
extends 'App::Ordo::Command::Base';

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);

sub name    { "cluster show" }
sub summary { "Show detailed information about a cluster (current if no path)" }
sub usage   { "[path]" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $path) = @_;

    my $res = $self->api->call('read_cluster', { name => $path });

    unless ($res->{success}) {
        say colored(["bold red"], "Cluster not found: $path");
        say $res->{message} if $res->{message};
        return;
    }

    my $c = $res;
    $path //= $c->{name};

    say colored(["bold cyan"], "Cluster: ") . colored(["bold white"], $c->{name});
    say colored(["cyan"], "Path: ") . $path;
    say colored(["cyan"], "State: ") . colored(["bold " . ($c->{jobstate} eq 'running' ? 'green' : 'yellow')], $c->{jobstate});
    say colored(["cyan"], "Description: ") . ($c->{description} || colored(["bright_black"], "none"));
    say colored(["cyan"], "Calendar: ") . ($c->{cal_name} ? $c->{cal_name} : colored(["bright_black"], "none"));
    say colored(["cyan"], "Created: ") . ($c->{creation_time}
        ? strftime("%a %b %d %H:%M:%S %Y", localtime($c->{creation_time}))
        : "unknown");

    if ($c->{needs} && keys %{$c->{needs}}) {
        my @all = grep { $c->{needs}{$_}{mode} == 0 } keys %{$c->{needs}};
        my @any = grep { $c->{needs}{$_}{mode} == 1 } keys %{$c->{needs}};
        say colored(["cyan"], "Depends on: ") . join(", ", @all) if scalar @all;
        say colored(["cyan"], "Depends on any: ") . join(", ", @any) if scalar @any;
    } else {
        say colored(["cyan"], "Dependencies: ") . colored(["green"], "(none)");
    }

    if ($c->{ended}) {
        my $ago = int(time - $c->{ended});
        my $when = $ago < 3600 ? "$ago seconds ago"
                 : $ago < 86400 ? int($ago/3600) . " hours ago"
                 : int($ago/86400) . " days ago";
        say colored(["cyan"], "Last run: ") . strftime("%a %b %d %H:%M:%S %Y", localtime($c->{ended}))
            . colored(["green"], " ($when)");
    } else {
        say colored(["cyan"], "Last run: ") . colored(["yellow"], "never");
    }

    if ($c->{jobs} && @{$c->{jobs}}) {
        say "\n" . colored(["bold green"], "Jobs in this cluster:");
        my $rows = [ [qw(ID NAME SERVER STATE SCRIPT)] ];
        for my $j (@{$c->{jobs}}) {
            my $state_color = $j->{jobstate} eq 'complete' ? 'green' :
                              $j->{jobstate} eq 'running'  ? 'magenta' :
                              $j->{jobstate} eq 'failed'   ? 'red' : 'yellow';
            push @$rows, [
                $j->{id},
                $j->{name},
                $j->{server_name} || '-',
                colored(["bold $state_color"], $j->{jobstate}),
                $j->{script} || '(no script)',
            ];
        }
        say generate_table(rows => $rows, header_row => 1, style => 'boxrule');
    } else {
        say colored(["yellow"], "\nNo jobs in this cluster");
    }
    say "";
}

1;
