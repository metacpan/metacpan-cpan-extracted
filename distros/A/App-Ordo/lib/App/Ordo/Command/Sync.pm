# lib/App/Ordo/Command/Sync.pm
package App::Ordo::Command::Sync;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8';
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "sync" }
sub summary { "Sync scheduler state with remote servers and detect zombie jobs" }
sub usage   { "" }

sub option_spec { {} }

sub execute {
    my ($self) = @_;

    say colored(["bold yellow"], "Synchronizing with all remote servers...");

    my $res = $self->api->call('sync', {});

    unless ($res->{success}) {
        say colored(["bold red"], "Sync failed: " . ($res->{message} || 'unknown error'));
        return;
    }

    my $msg = $res->{message} || "sync completed";
    my ($zombies, $revived) = $msg =~ /(\d+) zombies? found.*?(\d+) revived/;

    if ($zombies && $zombies > 0) {
        say colored(["bold red"], "$zombies zombie job(s) detected and marked");
        say colored(["yellow"], "$revived job(s) revived") if $revived;
    } else {
        say colored(["bold green"], "All good - no zombies found");
    }

    say colored(["bright_black"], $msg);
}

1;
