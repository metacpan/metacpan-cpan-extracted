#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 10;

use Archlinux::Term qw();

eval { msg() };
like $@, qr/Undefined subroutine/;

eval { status() };
like $@, qr/Undefined subroutine/;

eval { substatus() };
like $@, qr/Undefined subroutine/;

eval { warning() };
like $@, qr/Undefined subroutine/;

eval { error() };
like $@, qr/Undefined subroutine/;

Archlinux::Term::msg( 'This is only a test' );
ok !$@;

Archlinux::Term::status( 'Do not attempt to adjust your TV set' );
ok !$@;

Archlinux::Term::substatus( 'Emergency broadcast system' );
ok !$@;

{
    my $warned;
    local $SIG{__WARN__} = sub { $warned = 1; };
    Archlinux::Term::warning( 'I warned you!' );
    ok $warned;
}

eval { Archlinux::Term::error( 'Error!' ) };
like $@, qr/Error!/;
