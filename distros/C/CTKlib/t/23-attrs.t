#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 9;

use CTK::Util qw/:API/;

# Two args
{
    my ($foo, $bar) = read_attributes([
            "FOO",
            "BAR",
        ],
        -foo => "Foo",
        -bar => "Bar",
    );
    is($foo, "Foo", "Foo arg");
    is($bar, "Bar", "Bar arg");
}

# Incorrect (undefined) value
{
    my ($foo, $bar) = read_attributes([
            "FOO",
            "BAR",
        ],
        -foor => "Foo",
        -bar => "Bar",
    );
    is($foo, undef, "Foo arg (undef)");
    is($bar, "Bar", "Bar arg");
}


# Aliases
{
    my ($foo, $bar) = read_attributes([
            [qw/FOO FOOO FOOOF/],
            [qw/BAR BAAR BAAAR/],
        ],
        -foof => "Foo incorrect",
        -fooof => "Foo",
        -baar => "Bar",
    );
    is($foo, "Foo", "Foo arg");
    is($bar, "Bar", "Bar arg");
}

# WO dashes
{
    my ($foo, $bar) = read_attributes([
            [qw/FOO FOOO FOOOF/],
            [qw/BAR BAAR BAAAR/],
        ],
        foof => "Foo incorrect",
        fooof => "Foo",
        baar => "Bar",
    );
    is($foo, "Foo", "Foo arg");
    is($bar, "Bar", "Bar arg");
}

# No args
{
    my @a = read_attributes([
            [qw/FOO FOOO FOOOF/],
            [qw/BAR BAAR BAAAR/],
        ]);
    is(scalar(@a), 0, "No attrs") or diag(explain(\@a));
}

1;

__END__
