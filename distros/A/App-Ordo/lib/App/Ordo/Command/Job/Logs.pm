package App::Ordo::Command::Job::Logs;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';
use POSIX qw(strftime);

use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);

sub name    { "job logs" }
sub summary { "Show execution history for a job" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job logs <path/name>");
        return;
    }

    my $res = $self->api->call('find_log', { name => $name });

    unless ($res->{success} && $res->{logs}) {
        say colored(["bold yellow"], "No log history for '$name'");
        say $res->{message} if $res->{message};
        return;
    }

    say colored(["bold cyan"], "Log history for $name (" . scalar(@{$res->{logs}}) . " runs)\n");

    my $rows = [ [qw(ID STARTED ENDED DURATION EXIT SIGNAL PID)] ];
    for my $log (@{$res->{logs}}) {
        my $started = $log->{started} ? strftime("%b %d %H:%M:%S", localtime($log->{started})) : '-';
        my $ended   = $log->{ended}   ? strftime("%b %d %H:%M:%S", localtime($log->{ended}))   : '-';
        my $duration = $log->{ended} && $log->{started}
            ? sprintf("%ds", $log->{ended} - $log->{started})
            : '-';

        push @$rows, [
            $log->{id},
            $started,
            $ended,
            $duration,
            $log->{exit_code} // '-',
            $log->{signal} // '-',
            $log->{pid} // '-',
        ];
    }

    say generate_table(rows => $rows, header_row => 1, style => 'boxrule');
    say "\nUse 'job log <name> <id>' to view a specific run";
}

1;
