package App::Ordo::Command::User::Show;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);
use Text::Table::Tiny 1.02 qw(generate_table);

sub name    { "user show" }
sub summary { "Show current user information and client version" }
sub usage   { "" }

sub option_spec { {} }

sub execute {
    my ($self) = @_;

    # Get user info
    my $user_res = $self->api->call('read_user', {});

    if ($user_res->{success}) {
        say colored(["bold cyan"], "Current User\n");

        my $rows = [
            ["Key", "Value"],
            ["ID", $user_res->{id} // '-'],
            ["Email", $user_res->{email} // '-'],
            ["Name", $user_res->{name} // '(none)'],
            ["Level", $user_res->{level} // '-'],
            ["Org ID", $user_res->{org_id} // '-'],
            ["Current Path", $user_res->{path} // '-'],
            ["Mode", $user_res->{mode} // '-'],
            ["Remote Address", $user_res->{remote_address} // '-'],
        ];

        say generate_table(rows => $rows, header_row => 1, style => 'boxrule');
    } else {
        say colored(["bold red"], "Failed to retrieve user info");
        say $user_res->{message} if $user_res->{message};
    }
}

1;
