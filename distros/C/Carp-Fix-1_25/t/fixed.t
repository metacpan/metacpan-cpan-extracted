#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use Carp::Fix::1_25;
use Test::More;

# Don't risk windows\filenames from being interpreted as regex metacharacters
my $FILE  = __FILE__;
my $QFILE = quotemeta $FILE;

my $carp_version = $Carp::VERSION || "undef";
diag "with Carp $carp_version";

note "default exports"; {
    can_ok __PACKAGE__, "carp", "croak", "confess";
}

note "croak"; {
    ok !eval { croak "Goodbye world!"; 1; };
    like $@, qr{^Goodbye world! at $QFILE line @{[ __LINE__ -1 ]}\.\n};
}

note "message with newlines"; {
    ok !eval { croak "Line 1\nLine 2\n"; 1; };
    like $@, qr{^Line 1\nLine 2\n at $QFILE line @{[ __LINE__ -1 ]}\.\n};
}

note "confess"; {
    ok !eval { confess "Goodbye world!"; 1; };
    like $@, qr{^Goodbye world! at $QFILE line @{[ __LINE__ -1 ]}\.\n};
    unlike $@, qr{Carp::Fix}, "our internals don't show up in the stack";
}

note "carp"; {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, join "", @_ };

    carp "Gurk";
    like $warnings[0], qr{^Gurk at $QFILE line @{[ __LINE__ -1 ]}\.\n};    
    is @warnings, 1;
}

note "cluck"; {
    package Foo;
    use Test::More;
    use Carp::Fix::1_25 qw(cluck);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, join "", @_ };

    cluck "Stuffs";
    like $warnings[0], qr{^Stuffs at $QFILE line @{[ __LINE__ -1 ]}\.\n};
    unlike $@, qr{Carp::Fix}, "our internals don't show up in the stack";
    is @warnings, 1;
}

note "short/longmess"; {
    package Foo;
    use Test::More;
    use Carp::Fix::1_25 qw(longmess shortmess);

    is longmess("Foo"),  "Foo at $FILE line @{[ __LINE__ ]}.\n";
    is shortmess("Foo"), "Foo at $FILE line @{[ __LINE__ ]}.\n";
}

done_testing;
