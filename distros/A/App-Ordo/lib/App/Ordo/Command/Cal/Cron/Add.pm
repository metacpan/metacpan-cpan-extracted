package App::Ordo::Command::Cal::Cron::Add;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';
use Term::ANSIColor qw(colored);

sub name    { "cal cron add" }
sub summary { "Add a cron expression to a calendar" }
sub usage   { "<calendar> \"<cron expression\" [--description \"text\"]" }

sub option_spec {
    return {
        'description=s' => 'Description for this cron',
    };
}

sub execute {
    my ($self, $opt, $cal_name, $cron_expr) = @_;

    unless ($cal_name && $cron_expr) {
        say colored(["bold red"], "Usage: cal cron add <calendar> \"<cron>\" [--description \"...\"]");
        return;
    }

    my $res = $self->api->call('create_cron', {
        cal         => $cal_name,
        name        => $cron_expr,
        description => $opt->{description},
    });

    if ($res->{success}) {
        say colored(["bold green"], "Cron '$cron_expr' added to calendar '$cal_name'");
    } else {
        say colored(["bold red"], "Failed: " . ($res->{message} || 'calendar not found'));
    }
}

1;
