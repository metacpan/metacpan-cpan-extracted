package App::Ordo::Command::Cal::Create;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cal create" }
sub summary { "Create a new calendar" }
sub usage   { "<name> [--desc \"description\"]" }

sub option_spec {
    return {
        'description=s' => 'Description for the calendar',
        # No positional options in spec — name is taken from @args
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name) {
        say colored(["bold red"], "Error: calendar name is required");
        $self->show_help;
        return;
    }

    my $res = $self->api->call('create_cal', {
        name        => $name,
        tz          => $self->api->tz,
        description => $opt->{description},
    });

    if ($res->{success}) {
        say colored(["bold green"], "Calendar '$name' created successfully");
    } else {
        say colored(["bold red"], "Failed to create calendar: " . ($res->{message} || 'unknown error'));
    }
}

1;
