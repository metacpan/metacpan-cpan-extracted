use strict;
use warnings;
use Test::More tests => 16;
use CSS::Moonfall;

our $page_width = 800;

our $widths = fill {
    total => $page_width,
    left => undef,
    center => 600,
    right => undef,
};

is($widths->{total}, undef, "total no longer set");
is($widths->{center}, 600, "center remained set");
is($widths->{left}, 100, "left set to correct value");
is($widths->{right}, 100, "right set to correct value");

$widths = fill {
    total => 1000,
    left => undef,
    center => 600,
    right => undef,
};

is($widths->{total}, undef, "total no longer set");
is($widths->{center}, 600, "center remained set");
is($widths->{left}, 200, "left set to correct value");
is($widths->{right}, 200, "right set to correct value");

$widths = fill {
    total => 1000,
    left => 100,
    center => 600,
    right => undef,
};

is($widths->{total}, undef, "total no longer set");
is($widths->{center}, 600, "center remained set");
is($widths->{left}, 100, "left remained set");
is($widths->{right}, 300, "right set to correct value");

our $center_widths = fill {
    total => $widths->{center},
    left => undef,
    center => undef,
    right => undef,
};

is($center_widths->{total}, undef, "total no longer set");
is($center_widths->{left}, 200, "left set to correct value");
is($center_widths->{center}, 200, "center set to correct value");
is($center_widths->{right}, 200, "right set to correct value");

