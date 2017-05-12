#!/usr/local/bin/perl -w
#
# $Id: base.t,v 1.1 1997/08/12 16:02:12 mpeppler Exp $

# Base DBD Driver Test

use strict;
use Test::More tests => 5;

note( 'Test loading DBI, DBD::SQLAnywhere and version' );
require_ok( 'DBI' );

eval {
    import DBI;
};
ok( !$@, 'import DBI' );

my $switch = DBI->internal;
is( ref( $switch ), 'DBI::dr', 'internal' );

my $drh;
eval {
    $drh = DBI->install_driver( 'SQLAnywhere' );
};
my $ev = $@;
if( $ev ) {
    $ev =~ s/\n\n+/\n/g;
    warn "\n\n\n";
    warn "Note:\n";
    warn "\n";
    warn "Failed to load the DBD::SQLAnywhere driver or the SQL Anywhere client\n";
    warn "libraries. Ensure that SQLAnywhere has been installed and configured\n";
    warn "correctly and that demo.db has been started. Attempting to load\n";
    warn "DBD::SQLAnywhere reported the following error:\n";
    warn "    $ev\n";
    warn "The remaining tests will be skipped.\n\n";
    sleep( 5 );
}

SKIP: {
    skip( 'install_driver failed -- skipping remaining', 2 ) if $ev;

    is( ref( $drh ), 'DBI::dr', 'install_driver' );
    ok( $drh->{Version}, 'version' );
}
# end.
