#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use Acrux::DBI;
#use Acrux::DBI::Dump;
use Acrux::Util qw/ touch /;

plan skip_all => "Currently a developer-only test" unless -d ".git";
my $url = $ENV{DB_CONNECT_URL} or plan skip_all => "DB_CONNECT_URL required";
ok($url, 'DB_CONNECT_URL is correct') and note $url;

# Connect
my $dbi;
my $is_new = 0;
subtest 'Connecting' => sub {
    $dbi = Acrux::DBI->new($url, autoclean => 1)->connect;
    if (defined($dbi->dbh) && $dbi->driver eq 'sqlite') {
        my $file = $dbi->dbh->sqlite_db_filename();
        unless ($file && (-e $file) && !(-z $file)) {
            touch($file);
            $is_new = 1;
        }
    }
    ok(!$dbi->error, 'Connect to ' . $dbi->dsn) or diag $dbi->error;
    ok $dbi->ping, 'Connected' or return;
};

my $string = <<EOL;
CREATE TABLE `test` (`message` TEXT);

-- #foo
CREATE TABLE `pets` (`pet` TEXT);
INSERT INTO `pets` VALUES ('cat');
INSERT INTO `pets` VALUES ('dog');
delimiter //
CREATE PROCEDURE `test`()
BEGIN
  SELECT `pet` FROM `pets`;
END
//

-- #bar (...you can comment freely here...)
DROP TABLE `pets`;
DROP PROCEDURE `test`;

-- #baz
-- you can comment freely here
CREATE TABLE `stuff` (`whatever` INT);

-- # 1_00
DROP TABLE `stuff`;

-- # test
CREATE TABLE IF NOT EXISTS "test" ("message" TEXT DEFAULT NULL);
INSERT INTO "test" VALUES ("foo");
INSERT INTO "test" VALUES ("bar");

-- # tx
BEGIN TRANSACTION;
INSERT INTO "test" VALUES ("one");
INSERT INTO "test" VALUES ("two");
COMMIT;

EOL

#my $dump = Acrux::DBI::Dump->new(dbi => $dbi);
my $dump = $dbi->dump->from_string($string);
#note explain $dump->pool;

subtest 'Peek' => sub {
    my $main = $dump->peek;
    is(scalar @$main, 1, 'The "main" block contains 1 statement') or diag explain $main;
    my $bar = $dump->peek('bar');
    is(scalar @$bar, 2, 'The "bar" block contains 2 statements') or diag explain $bar;
    my $none = $dump->peek('none');
    is(scalar @$none, 0, 'The "none" block is empty or not exists') or diag explain $none;
    my @baz = $dump->peek('baz');
    is(scalar @baz, 1, 'The "baz" block contains 2 statements') or diag explain \@baz;
};

subtest 'Create table' => sub {
    $dump->poke('test');
    ok(!$dbi->error, 'Poked test dump') or diag $dbi->error;
} if $is_new;


subtest 'Transaction' => sub {
    $dump->poke('tx');
    ok(!$dbi->error, 'Poked tx dump') or diag $dbi->error;
};

#$dbi->disconnect; # Disabled this: see autoclean option

done_testing;

1;

__END__

DB_CONNECT_URL='sqlite://./test.db?sqlite_unicode=1' prove -lv t/05-dump.t

