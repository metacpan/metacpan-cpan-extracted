#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Helpers;    # Local helper routines used by the test suite.

use Test::More;
use Test::Fatal;

plan( skip_all => "utf8 macro support requires > 5.13.7" ) if $] < '5.013007';
plan tests => 5;

use CDB_File;

my ( $db, $db_tmp ) = get_db_file_pair(1);

my %a = qw(one Hello two Goodbye);
eval { CDB_File::create( %a, $db->filename, $db_tmp->filename, 'utf8' => 1 ) or die "Failed to create cdb: $!" };
is( "$@", '', "Create cdb" );

# Test that good file works.
tie( my %h, "CDB_File", $db->filename, 'utf8' => 0 ) and pass("Test that good file works");

like exception { delete $h{'one'} }, qr{^\QModification of a CDB_File attempted at t/clear.t\E}, "Test dies if you try to delete a key in a tied hash";
like exception { $h{'one'} = 5 }, qr{^\QModification of a CDB_File attempted at t/clear.t\E}, "Test dies if you try to modify a key in a tied hash";

my $t = tied %h;

like exception { $t->CLEAR }, qr{^\QModification of a CDB_File attempted at t/clear.t\E}, "Test dies if you try to clear the tied hash";

exit;
