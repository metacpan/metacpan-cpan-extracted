#!/usr/bin/perl -w
use strict;
use Test::More;
use DBI;

my $have_win32_ole = eval {
    require Win32::OLE;
    1;
};

plan tests => 1;

if (! $have_win32_ole) {
    pass "(not applicable on this system)";
} else {

    my $dbh = DBI->connect('dbi:WMI:');
    isa_ok $dbh, 'DBI::db';
}
