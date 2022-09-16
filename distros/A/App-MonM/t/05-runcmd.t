#!/usr/bin/perl -w
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
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 5;

use App::MonM::Util qw/run_cmd/;


# Without timeouts
{
    my $r = run_cmd("perl -w", 0, 'print q/Oops/; print STDERR q/My error/; exit 3');
    is($r->{status}, 0, "Status");
    is($r->{code}, 3, "Code");
    is($r->{stdout}, "Oops", "StdOut");
    #note(explain($r));
}


# With timeout
{
    my $r = run_cmd("perl -w", 2, 'print q/Oops/; sleep 5');
    is($r->{status}, 0, "Status=0");
    is($r->{code}, -1, "Code=-1");
    #note(explain($r));
}

1;

__END__