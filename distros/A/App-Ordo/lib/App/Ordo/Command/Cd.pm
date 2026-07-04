package App::Ordo::Command::Cd;
use Moo;
extends 'App::Ordo::Command::Base';
use feature qw(say);
use utf8;
use open ':std', ':utf8';
use App::Ordo qw($CURRENT_PATH);
use Term::ANSIColor qw(colored);
#use Text::Table::Tiny 1.02 qw(generate_table);

sub name    { "cd" }
sub summary { "Change current cluster" }
sub usage   { "<path>" }

# No options — pure positional
sub option_spec { {} }

sub execute {
    my ($self, $opt, $target) = @_;

    my $res = $self->api->call('change_cluster', { name => $target });

    if ($res->{success}) {
        $App::Ordo::CURRENT_PATH = $res->{path};
    } else {
        say colored(["bold red"], "Cannot cd to '$target': " . ($res->{message} || 'not found'));
    }
}

1;
