package App::Ordo::Command::Cal::Delete;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cal delete" }
sub summary { "Delete a calendar and all its cron expressions" }
sub usage   { "<calendar-name>" }
sub aliases { ['cal rm'] }

sub option_spec {
    return {
        'force' => 'Force delete even if attached to clusters',
    };
}

sub execute {
    my ($self, $opt, $cal_name) = @_;

    unless ($cal_name) {
        say colored(["bold red"], "Usage: cal delete <calendar-name> [--force]");
        say "Use --force if the calendar is attached to clusters";
        return;
    }

    my $payload = { name => $cal_name };
    $payload->{force} = 1 if $opt->{force};

    my $res = $self->api->call('delete_cal', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Calendar '$cal_name' deleted");
        say "All associated cron expressions removed (cascade delete)";
    } else {
        say colored(["bold red"], "Failed to delete calendar: " . ($res->{message} || 'unknown error'));
    }
}

1;
