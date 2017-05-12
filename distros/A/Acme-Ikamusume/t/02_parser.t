use strict;
use warnings;
use Test::Base;
plan tests => 1 * blocks;

use Acme::Ikamusume;

run {
    my $block = shift;
    
    my $output = Acme::Ikamusume->geso($block->input);
    is($output, $block->expected, $block->name);
};

__DATA__
=== 0 but true
--- reported: http://twitter.com/ttakah/status/14160980556648450
--- input:    0
--- expected: 0

=== empty
--- input eval
""
--- expected eval
""

=== undef
--- input eval
undef
--- expected eval
""
