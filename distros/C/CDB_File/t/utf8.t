#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Helpers;    # Local helper routines used by the test suite.

use Test::More;

plan( skip_all => "utf8 macro support requires > 5.13.7" ) if $] < '5.013007';
plan tests => 5;

use CDB_File;

my ( $db, $db_tmp ) = get_db_file_pair(1);

# He breaks everyone else's database, let's make sure he doesn't break ours :P
my $avar = my $latin_avar = "\306var";
utf8::upgrade($avar);

# Dang accents!
my $leon = "L\350on";
utf8::upgrade($leon);

my %a = qw(one Hello two Goodbye);
$a{$avar} = $leon;
eval { CDB_File::create( %a, $db->filename, $db_tmp->filename, 'utf8' => 1 ) or die "Failed to create cdb: $!" };
is( "$@", '', "Create cdb" );

my %h;

# Test that good file works.
tie( %h, "CDB_File", $db->filename, 'utf8' => 1 ) and pass("Test that good file works");
is $h{$avar},       $leon, "Access a utf8 key";
is $h{$latin_avar}, $leon, "Access a utf8 key using its latin1 record.";
is( utf8::is_utf8($latin_avar), '', "\$latin_avar is not converted to utf8" );

exit;
