#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use FindBin qw/$Bin/;
use Data::Dumper;

use lib "$Bin/../lib";
use ActiveRecord::Simple::Migration;
use ActiveRecord::Simple;


eval { require DBD::SQLite } or plan skip_all => 'Need DBD::SQLite for testing';


ActiveRecord::Simple->connect("dbi:SQLite:dbname=:memory:","",""); ### TODO: skip plan if error
my $dbh = ActiveRecord::Simple->dbh;
$dbh->do("CREATE TABLE `mytest` (field1 VARCHAR(100) NOT NULL)");


my $num = 1;
ok ActiveRecord::Simple::Migration::new('test', $num), 'new';
ok -e "$num-UP.sql";
ok -e "$num-DN.sql";

open my $up_fh, ">>", "$num-UP.sql";
say {$up_fh} "INSERT INTO `mytest` (field1) VALUES ('hello');";
close $up_fh;

open my $dn_fh, ">>", "$num-DN.sql";
say {$dn_fh} "DELETE FROM `mytest` WHERE field1 = 'hello';";
close $dn_fh;

ok ActiveRecord::Simple::Migration::up($dbh, $num), 'up';
my ($hello) = $dbh->selectrow_array(q{SELECT field1 FROM mytest WHERE field1 = 'hello'});
is $hello, 'hello';

ok ActiveRecord::Simple::Migration::down($dbh, $num), 'down';
($hello) = $dbh->selectrow_array(q{SELECT field1 FROM mytest WHERE field1 = 'hello'});
is $hello, undef;

unlink "$num-UP.sql";
unlink "$num-DN.sql";

done_testing();
