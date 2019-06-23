use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Test::Base;

use Code::TidyAll::Plugin::Spellunker;
use Path::Tiny qw/path/;

sub provide {
    Code::TidyAll::Plugin::Spellunker->new(
        name      => 'Spellunker',
        tidyall   => Test::MockObject->new,
        stopwords => 'karupanerura',
    );
}

plan tests => 1 * blocks;

for my $block (blocks) {
    my $plugin = provide();

    eval { $plugin->validate_source($block->input) };
    my $e = $@;

    is $@, $block->expected;
}

__END__
=== Valid
--- input
This is valid.
--- expected

=== Invalid
--- input
This is invaliddddd!
--- expected
Errors:
    1: invaliddddd
