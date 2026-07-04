package App::Ordo::Command::Cal::List;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8'; # Set STDOUT and STDERR to UTF-8
extends 'App::Ordo::Command::Base';
use POSIX qw(strftime);

use Term::ANSIColor qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);

sub name    { "cal list" }
sub summary { "List all calendars and their cron expressions" }
sub usage   { "[calendar-name]" }
sub aliases { ['cal ls'] }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $filter_name) = @_;

    my $res = $self->api->call('find_cal', {});
    unless ($res->{success} && scalar @{ $res->{cals} }) {
       say colored(["bold yellow"], "No calendars found");
       return;
    }

    my @cals = @{$res->{cals} || []};

    # Optional: filter by name
    if ($filter_name) {
        @cals = grep { ($_->{name} || '') eq $filter_name } @cals;
        unless (@cals) {
            say colored(["bold yellow"], "No calendar found with name: $filter_name");
            return;
        }
    }

    say colored(["bold cyan"], "Calendars (" . scalar(@cals) . " found):\n");

    for my $cal (@cals) {
        my $name = $cal->{name} || colored(["yellow"], "(unnamed id:$cal->{id})");
        my $desc = $cal->{description} ? " - $cal->{description}" : "";
        my $attached = $cal->{cluster_ids} && @{$cal->{cluster_ids}}
            ? " (attached to " . scalar(@{$cal->{cluster_ids}}) . " clusters)"
            : "";

        say colored(["bold white"], "  $name$desc$attached");

        my $crons = $cal->{crons} || [];
        if (@$crons) {
            my $rows = [ [qw(ID CRON NEXT_START DESCRIPTION)] ];
            for my $cron (@$crons) {
                my $next = $cron->{next_start}
                    ? strftime("%Y-%m-%d %H:%M", localtime($cron->{next_start}))
                    : '-';
                my $desc = $cron->{description} || $cron->{english} || '';
                push @$rows, [
                    $cron->{id},
                    $cron->{name},
                    $next,
                    $desc,
                ];
            }
            say generate_table(rows => $rows, header_row => 1, style => 'boxrule');
        } else {
            say "    (no cron expressions)";
        }
        say ""; # spacing
    }
}

1;
