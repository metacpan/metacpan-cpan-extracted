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

use Test::More; # qw/no_plan/
plan tests => 6;

use_ok qw/CTK::Timeout/;

my $to = CTK::Timeout->new();

# TimeOut
{
    my $cd = sub {
        #note shift;
        sleep 2;
        #note shift;
        1;
    };

    my $retval = $to->timeout_call($cd => 1, "foo", "bar");
    note $to->error if $to->error;

    ok(!$retval, "RetVal 1 is false");
}

# No TimeOut error
{
    my $cd = sub {
        die "Test exception";
    };

    my $retval = $to->timeout_call($cd => 0, "foo", "bar");
    ok($to->error, "Test die") && note $to->error;
    ok(!$retval, "RetVal 2 is false and die");
}

# No errors (retval = true)
{
    my $cd = sub {
        1;
    };

    my $retval = $to->timeout_call($cd => 0, "foo", "bar");
    ok($retval, "RetVal 3 is true");
}

# No errors (retval = false)
{
    my $cd = sub {
        0;
    };

    my $retval = $to->timeout_call($cd => 0, "foo", "bar");
    ok(!$retval, "RetVal 4 is false");
}

1;

__END__

prove -lv t/27-timeout.t
