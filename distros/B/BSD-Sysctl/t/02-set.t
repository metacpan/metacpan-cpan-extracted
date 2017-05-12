# 02-set.t
# Advanced sanity checks for BSD::Sysctl
#
# Copyright (C) 2006 David Landgren

use strict;

use Test::More tests => 10;
use BSD::Sysctl qw(sysctl sysctl_set);

SKIP: {
    skip( 'Not running as root (probably a sane decision)', 10 )
        if $<;
    skip( 'TEST_BSD_SYSCTL_NAME environment variable not set', 10 )
        unless exists $ENV{TEST_BSD_SYSCTL_NAME};
    skip( 'TEST_BSD_SYSCTL_VALUE environment variable not set', 10 )
        unless exists $ENV{TEST_BSD_SYSCTL_VALUE};

    my $variable = $ENV{TEST_BSD_SYSCTL_NAME};
    my $value    = $ENV{TEST_BSD_SYSCTL_VALUE};

    my $original = sysctl($variable);
    diag( "$variable initial value: $original" );
    ok(defined($original), "able to read $variable") or diag "err=$!";

    if ($value eq $original) {
        diag( <<DIAG );
Note that the new value of $variable is the same as the old.
Therefore it might not be obvious if things are being changed.
DIAG
    }

    my $ret = sysctl_set($variable, $value);
    ok(defined($ret), "able to set $variable to $value") or diag "err=$!";

    my $new = sysctl($variable);
    is( $new, $value, "read back the new value" );

    $ret = sysctl_set($variable, $original);
    ok(defined($ret), "able to reset $variable to $original") or diag "err=$!";

    $new = sysctl($variable);
    is( $new, $original, "read back the old value" );
    diag( "$variable restored value: $new" );

    {
        my $obj = BSD::Sysctl->new($variable);
        my $original = $obj->get();
        diag( "$variable initial value: $original" );
        ok(defined($original), "able to oo-read $variable") or diag "err=$!";

        my $ret = $obj->set($value);
        ok(defined($ret), "able to oo-set $variable to $value") or diag "err=$!";

        my $new = $obj->get();
        is( $new, $value, "oo-read back the new value" );

        $ret = $obj->set($original);
        ok(defined($ret), "able to oo-reset $variable to $original") or diag "err=$!";

        $new = $obj->get();
        is( $new, $original, "oo-read back the old value" );
        diag( "$variable restored value: $new" );
    }
}
