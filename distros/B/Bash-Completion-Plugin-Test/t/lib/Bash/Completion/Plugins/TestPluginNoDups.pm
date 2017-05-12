package Bash::Completion::Plugins::TestPluginNoDups;

use strict;
use warnings;
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(prefix_match);
use Text::ParseWords qw(shellwords);

my @OPTIONS = qw{foo bar baz};

sub should_activate {
    return [ 'test-plugin-nodup' ];
}

sub complete {
    my ( $self, $r ) = @_;

    my %remaining = map { $_ => 1 } @OPTIONS;

    my @words = shellwords($r->line);

    foreach my $word (@words) {
        next if $word eq $r->word;

        delete $remaining{$word};
    }

    $r->candidates(prefix_match($r->word, keys %remaining));
}

1;
