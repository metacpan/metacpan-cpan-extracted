package App::Ordo::Command::Server::Add;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);
use Term::ReadKey;

sub name    { "server add" }
sub summary { "Add a new worker server" }
sub usage   { "<name> --host <hostname> --user <username> [--password] [--port 22]" }

sub option_spec {
    return {
        'host=s'      => 'Hostname or IP address (required)',
        'user=s'      => 'SSH username (required)',
        'port=i'      => 'SSH port (default: 22)',
        'password'    => 'Prompt for password (optional — key auth preferred)',
    };
}

sub execute {
    my ($self, $opt, $name) = @_;

    unless ($name && $opt->{host} && $opt->{user}) {
        say colored(["bold red"], "Missing required: name, --host, --user");
        $self->show_help;
        return;
    }

    my $password;
    if ($opt->{password}) {
        print "Password for $opt->{user}\@$opt->{host}: ";
        ReadMode('noecho');
        chomp($password = <STDIN>);
        ReadMode('normal');
        print "\n";
    }

    my $payload = {
        name     => $name,
        host     => $opt->{host},
        user     => $opt->{user},
        port     => $opt->{port} // 22,
        password => $password,
    };

    my $res = $self->api->call('create_monitor', $payload);

    if ($res->{success}) {
        say colored(["bold green"], "Server '$name' ($opt->{host}) added successfully");
    } else {
        say colored(["bold red"], "Failed to add server: " . ($res->{message} || 'unknown error'));
    }
}

1;
