#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

#use Test::More;
use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

{
    note "R ", ord("\r");
    note "N ",ord("\n");

    foreach my $sep (
        "\n",      # linux line ending
        "\r\n",    # DOS line ending
        "\n\r",    # kind of broken but why not
        "\n\n"     # double new lines... should not impact anything
    ) {
        my $q = $sep;
        $q =~ s{\n}{\\n}g;
        $q =~ s{\r}{\\r}g;

        note "Separataror is ", $q;

        # kind of a combo test
        my $content = join(
            $sep,
            'key1:value',
            'key2: value',
            '# a comment',
            '',
            '# empty line above',
            'not a column',
            'last:value',
        );

        is Colon::Config::read($content),
            [
            key1 => 'value',
            key2 => 'value',
            last => 'value',
            ],
            "read xs with sep='$q'";

        is Colon::Config::read_as_hash($content),
            { @{ Colon::Config::read($content) // [] } },
            "read_as_hash sep='$q'";

    }

}

done_testing;

__END__
