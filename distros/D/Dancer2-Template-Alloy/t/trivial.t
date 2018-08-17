#!/usr/bin/env perl

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}
use Test::More tests => 1;
use Dancer2::Template::Alloy ();

sub process {
    my $stash    = shift;
    my $input    = shift;
    my $expected = shift;
    my $message  = shift || 'Template processed ok';
    my $output   = '';

    $output = Dancer2::Template::Alloy->new->process(
        \$input,
        $stash
    );
    is( $output, $expected, $message );
}


######################################################################
# Main Tests

process( { foo => 'World' },
    <<'END_TEMPLATE', <<'END_EXPECTED', 'Trivial ok' );
Hello [% foo %]!
END_TEMPLATE
Hello World!
END_EXPECTED
