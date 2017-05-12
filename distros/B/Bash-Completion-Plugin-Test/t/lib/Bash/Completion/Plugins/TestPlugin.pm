package Bash::Completion::Plugins::TestPlugin;

use strict;
use warnings;
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(prefix_match);

my @OPTIONS = qw{foo bar baz};

sub should_activate {
    return [ 'test-plugin' ];
}

sub complete {
    my ( $self, $r ) = @_;

    $r->candidates(prefix_match($r->word, @OPTIONS));
}


1;
