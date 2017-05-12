#!perl

use strict;
use Test::More;

use lib 't/lib';
use Mock::Syslog;

use Carp::Syslog;

warn "warn1\n";
warn "warn2\n";

{
    no Carp::Syslog;
    warn "warn3\n";
}

eval {
    die "die1\n";
};

eval {
    # References are not logged . . .
    die \my $ref;
};

eval {
    # . . . unless they can stringify.
    die do {
        package MyTest;
        use overload '""' => sub { return 'die2' };
        bless {}, 'MyTest';
    };
};

is_deeply \@Mock::Syslog::WARN, [ qw( warn1 warn2 ) ];
is_deeply \@Mock::Syslog::DIE,  [ qw( die1 die2 ) ];

done_testing;
