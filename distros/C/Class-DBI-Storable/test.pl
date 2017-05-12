use strict;
use Test::More;
use Test::Warn;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 10);
}

use Class::DBI;
use Scalar::Util qw(refaddr);
use Storable qw(freeze thaw dclone);
use File::Temp qw/tempfile/;

my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
END { unlink $DB if -e $DB }

{
    package CDBI;
    #use base 'Class::DBI';
    #use Class::DBI::Storable;
    use base qw(Class::DBI Class::DBI::Storable);
    CDBI->connection(@DSN);

    CDBI->db_Main->do("create temp table cdbi (
                            id integer primary key,
                            bizo
                    )");
    CDBI->table('cdbi');
    CDBI->columns(Primary => 'id');
    CDBI->columns(Essential => 'bizo');
}

CDBI->create({ id => 1, bizo => 2 });

my $refaddr;
my $o = CDBI->retrieve(1);
$refaddr = refaddr($o), "\n";
is refaddr(CDBI->retrieve(id => 1)), $refaddr, "retrieve gives the same object";
my $round_tripped = eval { thaw(freeze($o)) };
is $@, '', "freeze+thaw ran without error";
is ref($round_tripped), "CDBI", "thaw produced a CDBI object";
is refaddr($round_tripped), $refaddr, "freeze+thaw returned the same object";

$o->bizo(5);
warning_like { freeze($o) } 
    qr/Warning, freezing CDBI discards unsaved changes/,
    "freeze with unsaved changes warns";
$Class::DBI::Storable::FreezeCarp = 0;
warning_like { freeze($o) } undef, "warning can be suppressed";

my $clone;
warning_like { $clone = dclone($o) } 
    qr/Warning, cloning a Class::DBI object/, 
    "dclone warns";

isnt refaddr($clone), $refaddr, "dclone returns a different object";
is_deeply $clone, $o, "dclone clones";

$Class::DBI::Storable::CloneCarp = 0;
warning_like { $clone = dclone($o) } undef, "warning can be suppressed";

1;

