#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BackupPC::Backups::Info' ) || print "Bail out!\n";
}

diag( "Testing BackupPC::Backups::Info $BackupPC::Backups::Info::VERSION, Perl $], $^X" );
