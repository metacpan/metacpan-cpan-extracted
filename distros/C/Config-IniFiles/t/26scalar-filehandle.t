#!/usr/bin/perl
# This script is a regression test for:
#
# https://rt.cpan.org/Ticket/Display.html?id=54997
#
# Failure to read the ini file contents from a filehandle made out of a scalar
#
# <<< [patch] stat() on unopened filehandle warning thrown when using
# filehandle made from a scalar. >>>

use Test::More;

use strict;
use warnings;

use Carp qw(cluck);
use English qw(-no_match_vars);

use Config::IniFiles;

if ( !eval { require 5.008; } )
{
    plan skip_all =>
"We need filehandles made from scalar which is a feature of Perl above 5.8.x";
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

    open my $scalar_fh, "<", \$contents;

    my $conf = eval {
        $WARNING = 1;
        $SIG{__WARN__} = \&Carp::croak;
        Config::IniFiles->new( -file => $scalar_fh );
    } or warn $EVAL_ERROR;

    # TEST
    ok( !$EVAL_ERROR,
        "Object was initialised from filehandle made out of a scalar." );

    # TEST
    is( $conf->val( "section1", "key" ), "val", "Object works." );

    undef $conf;
    close $scalar_fh;
}

