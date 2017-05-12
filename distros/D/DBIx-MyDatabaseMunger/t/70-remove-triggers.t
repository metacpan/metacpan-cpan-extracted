#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 27;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

sub t_add_trigger_fragment()
{
    my $fh;
    open $fh, ">", "trigger/10-allone.before.insert.Service.sql";
    print $fh <<EOF;
SET NEW.owner_id = 1;
EOF
    close $fh;
}

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);
my $ret;

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "run pull" );

# Add triggers
mkdir "trigger" unless -d "trigger";

my $fh;

open $fh, ">", "trigger/10-test.before.insert.Service.sql";
print $fh <<EOF;
SET NEW.description = 'Overridden before insert.';
EOF
close $fh;

open $fh, ">", "trigger/10-test.before.update.Service.sql";
print $fh <<EOF;
SET NEW.description = 'Overridden before update.';
EOF
close $fh;

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push with new triggers" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull to get new triggers" );

$ret = system(qw(diff -ur table t/70-remove-triggers.init.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/70-remove-triggers.init.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur trigger t/70-remove-triggers.init.d/trigger));
ok( $ret == 0, "check pull trigger sql" );

# Create another trigger fragment that is local only
t_add_trigger_fragment();

# Run pull again without --remove
$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull without --remove=any" );

$ret = system(qw(diff -ur table t/70-remove-triggers.noremove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/70-remove-triggers.noremove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur trigger t/70-remove-triggers.noremove.d/trigger));
ok( $ret == 0, "check pull trigger sql" );

# Run pull again with --remove=any
$ret = system( @cmdroot, "--remove=any", "pull" );
ok( $ret == 0, "pull with --remove=any" );

$ret = system(qw(diff -ur table t/70-remove-triggers.init.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/70-remove-triggers.init.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur trigger t/70-remove-triggers.init.d/trigger));
ok( $ret == 0, "check pull trigger sql" );

ok( ! -e "trigger/10-allone.before.insert.Service.sql", "check trigger fragment was removed." );

# Now remove one of the local trigger fragments.
unlink "trigger/10-test.before.insert.Service.sql";

# Push without --remove=any should leave the trigger in the database.
$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push without --remove=any" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull to check results of push without --remove=any" );

# We should be back to the initial state
$ret = system(qw(diff -ur table t/70-remove-triggers.init.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/70-remove-triggers.init.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur trigger t/70-remove-triggers.init.d/trigger));
ok( $ret == 0, "check pull trigger sql" );

# Again remove one of the local trigger fragments.
unlink "trigger/10-test.before.insert.Service.sql";

# Push with --remove=any.
$ret = system( @cmdroot, qw(--remove=any push) );
ok( $ret == 0, "push with --remove=any" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull to check results of push with --remove=any" );

$ret = system(qw(diff -ur table t/70-remove-triggers.remove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/70-remove-triggers.remove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur trigger t/70-remove-triggers.remove.d/trigger));
ok( $ret == 0, "check pull trigger sql" );

ok( ! -e "trigger/10-test.before.insert.Service.sql", "check trigger fragment was removed from database." );

exit 0;
