#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

sub write_modification
{
    open my $fh, ">", "view/ServiceWithOwner.sql";
    print $fh <<EOF;
CREATE VIEW `ServiceWithOwner` AS
SELECT s.name service_name, s.description service_description, o.name owner_name
FROM Service s JOIN User o ON s.owner_id=o.id;
EOF
}

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);
my $ret;

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "run pull" );

write_modification();

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push modified view" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(diff -ur table t/55-modify-view.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/55-modify-view.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

$ret = system(qw(diff -ur view t/55-modify-view.d/view));
ok( $ret == 0, "check pull view sql" );

exit 0;
