#!/usr/bin/perl

# This script is a regression test for:
#
# https://rt.cpan.org/Ticket/Display.html?id=45588
#
# Failure to read the ini file contents from a scalar

use Test::More;

use strict;
use warnings;

use Config::IniFiles;

if ( !eval { require IO::Scalar; } )
{
    plan skip_all => "IO::Scalar is not available";
}
else
{
    plan tests => 2;
}

{
    my $contents = <<'EOF';
[section1]
key = val
EOF

    my $conf = Config::IniFiles->new( -file => \$contents );

    # TEST
    ok( $conf, "Object was initialised from reference to scalar." );

    # TEST
    is( $conf->val( "section1", "key" ), "val", "Object works." );
}

