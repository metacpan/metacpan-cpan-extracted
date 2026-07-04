package App::Ordo::Command::Cal::Show;
use Moo;
extends 'App::Ordo::Command::Base';
use feature qw(say);
use POSIX qw(strftime);

use Term::ANSIColor qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);

sub name    { "cal show" }
sub summary { "Show detailed information about a calendar" }
sub usage   { "<calendar-name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $cal_name) = @_;

    unless ($cal_name) {
        say colored(["bold red"], "Usage: cal show <calendar-name>");
        return;
    }

    my $res = $self->api->call('find_cal', { name => $cal_name });

    unless ($res->{success}) {
        say colored(["bold red"], "Calendar not found: $cal_name");
        say "  " . ($res->{message} || '');
        return;
    }

    my ($cal) = grep { ($_->{name} || '') eq $cal_name } @{$res->{cals} || []};
    unless ($cal) {
        say colored(["bold red"], "Calendar '$cal_name' not found");
        return;
    }

    my $name = $cal->{name} || colored(["yellow"], "(unnamed id:$cal->{id})");
    my $tz = $cal->{tz} ? "$cal->{tz}" : "";
    my $desc = $cal->{description} ? " - $cal->{description}" : "";
    my $attached = $cal->{cluster_ids} && @{$cal->{cluster_ids}}
        ? join(", ", @{$cal->{cluster_ids}})
        : "(not attached)";

    say colored(["bold cyan"], "Calendar: $name$desc");
    say colored(["bold cyan"], "TimeZone: $tz");
    say colored(["bold cyan"], "Attached: $attached\n");

    my $crons = $cal->{crons} || [];
    if (@$crons) {
        my $rows = [ [qw(ID CRON NEXT_START DESCRIPTION)] ];
        for my $cron (@$crons) {
            my $next = $cron->{next_start}
                ? strftime("%Y-%m-%d %H:%M", localtime($cron->{next_start}))
                : '-';
            my $desc = $cron->{description} || $cron->{english} || '';
            push @$rows, [ $cron->{id}, $cron->{name}, $next, $desc ];
        }
        say generate_table(rows => $rows, header_row => 1, style => 'boxrule');
    } else {
        say colored(["yellow"], "  (no cron expressions defined)");
    }
}

1;
