#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;

sub write_modification
{
    open my $fh, ">", "table/Service.sql";
    print $fh <<EOF;
CREATE TABLE `Service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric service identifier.',
  `name` varchar(64) NOT NULL COMMENT 'Unique text service identifier.',
  `owner_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to user that owns service.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for Service.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of Service last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service creation.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `Service_owner` (`owner_id`),
  CONSTRAINT `Service_owner` FOREIGN KEY (`owner_id`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A User''s Service'
EOF
    close $fh;

    open $fh, ">", "view/ServiceWithOwner.sql";
    print $fh <<EOF;
CREATE VIEW `ServiceWithOwner` AS
SELECT s.name service_name, o.name owner_name, o.email owner_email
FROM Service s JOIN User o ON s.owner_id=o.id;
EOF
    close $fh;
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
ok( $ret == 0, "push without drop columns" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(diff -ur table t/50-drop-columns.nodrop.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur procedure t/50-drop-columns.nodrop.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

write_modification();

$ret = system( @cmdroot, "--drop-columns", "push" );
ok( $ret == 0, "push with drop columns" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(diff -ur table t/50-drop-columns.yesdrop.d/table));
ok( $ret == 0, "check pull table sql" );

$ret = system(qw(diff -ur view t/50-drop-columns.yesdrop.d/view));
ok( $ret == 0, "check pull view sql" );

$ret = system(qw(diff -ur procedure t/50-drop-columns.yesdrop.d/procedure));
ok( $ret == 0, "check pull procedure sql" );

exit 0;
