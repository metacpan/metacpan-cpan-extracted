#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

sub t_add_procedure_sql()
{
    my $fh;
    open $fh, ">", "procedure/create_user.sql";
    print $fh <<EOF;
CREATE DEFINER=`example`@`localhost` PROCEDURE `create_user`(IN name VARCHAR(64), IN email VARCHAR(64), OUT id INT UNSIGNED)
BEGIN
    INSERT INTO User (name,email) VALUES (name,email);
    SELECT LAST_INSERT_ID() INTO id;
END
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

# Add procedure
t_add_procedure_sql();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "Run pull without --remove=any" );

$ret = system(qw(diff -ur table t/80-procedures.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/80-procedures.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system( @cmdroot, "--remove=any", "pull" );
ok( $ret == 0, "pull with --remove=any" );

$ret = system(qw(diff -ur table t/80-procedures.remove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/80-procedures.remove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

ok( !-e "procedure/create_user.sql", "check procedure sql was removed." );

t_add_procedure_sql();

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push" );

clear_directories();

$ret = system( @cmdroot, "pull" );
$ret = system(qw(diff -ur table t/80-procedures.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/80-procedures.d/procedure));
ok( $ret == 0, "check pull procedure sql" );


# Remove local sql then test push without remove
unlink "procedure/create_user.sql";

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push" );

clear_directories();

$ret = system( @cmdroot, "pull" );
$ret = system(qw(diff -ur table t/80-procedures.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/80-procedures.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

# Remove local sql then test push with remove
unlink "procedure/create_user.sql";

$ret = system( @cmdroot, "--remove=any", "push" );
ok( $ret == 0, "push --remove=any" );

clear_directories();

$ret = system( @cmdroot, "pull" );
$ret = system(qw(diff -ur table t/80-procedures.remove.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/80-procedures.remove.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

exit 0;
