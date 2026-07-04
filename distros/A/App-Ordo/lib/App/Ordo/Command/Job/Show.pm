package App::Ordo::Command::Job::Show;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use POSIX qw(strftime);
use Term::ANSIColor qw(colored);
use App::Ordo qw($CURRENT_PATH);

sub name    { "job show" }
sub summary { "Show detailed information about a job" }
sub usage   { "<path/name>" }

sub option_spec { {} }

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Usage: job show <path/name>");
        return;
    }

    my $res = $self->api->call('read_job', { name => $name });

    unless ($res->{success}) {
        say colored(["bold red"], "Job not found: $name");
        say $res->{message} if $res->{message};
        return;
    }

    my $j = $res;

    say colored(["bold cyan"], "Job: ") . colored(["bold white"], $j->{name});
    say colored(["cyan"], "Path: ") . $name;
    say colored(["cyan"], "Server: ") . ($j->{server_name} || colored(["yellow"], "not assigned"));

    my $state_color = $j->{jobstate} eq 'complete' ? 'green' :
                      $j->{jobstate} eq 'running'  ? 'magenta' :
                      $j->{jobstate} eq 'failed'   ? 'red' :
                      $j->{jobstate} eq 'waiting'  ? 'yellow' : 'white';
    say colored(["cyan"], "State: ") . colored(["bold $state_color"], $j->{jobstate});

    say colored(["cyan"], "Script: ") . ($j->{script} || colored(["yellow"], "(none)"));
    say colored(["cyan"], "Description: ") . ($j->{description} || colored(["green"], "(none)"));

    if ($j->{needs} && keys %{$j->{needs}}) {
        my @all = grep { $j->{needs}{$_}{mode} == 0 } keys %{$j->{needs}}; 
        my @any = grep { $j->{needs}{$_}{mode} == 1 } keys %{$j->{needs}}; 
        say colored(["cyan"], "Depends on: ") . join(", ", @all) if scalar @all;
        say colored(["cyan"], "Depends on any: ") . join(", ", @any) if scalar @any;
    } else {
        say colored(["cyan"], "Dependencies: ") . colored(["green"], "(none)");
    }

    say colored(["cyan"], "Created: ") . ($j->{creation_time}
        ? strftime("%a %b %d %H:%M:%S %Y", localtime($j->{creation_time}))
        : "unknown");

    if ($j->{ended}) {
        my $ago = int(time - $j->{ended});
        my $when = $ago < 3600 ? "$ago seconds ago"
                 : $ago < 86400 ? int($ago/3600) . " hours ago"
                 : int($ago/86400) . " days ago";
        say colored(["cyan"], "Last run: ") . strftime("%a %b %d %H:%M:%S %Y", localtime($j->{ended}))
            . colored(["green"], " ($when)");
        #say colored(["cyan"], "Exit code: ") . ($j->{exit_code} == 0 ? colored(["green"], "0") : colored(["red"], $j->{exit_code}));

    } else {
        say colored(["cyan"], "Last run: ") . colored(["yellow"], "never");
    }

    say "";
}

1;
