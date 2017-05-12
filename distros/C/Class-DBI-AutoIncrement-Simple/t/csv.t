#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    my @missingDeps;
    eval "use File::Temp  qw/ tempfile tempdir /";
    push @missingDeps, 'File::Temp' if $@;
    eval "use File::Basename qw/basename dirname/";
    push @missingDeps, 'File::Basename' if $@;
    eval "use DBD::CSV";
    push @missingDeps, 'DBD::CSV' if $@;
    plan skip_all => __FILE__ . " requires: " . join(', ',@missingDeps) if @missingDeps;
    plan tests => 22;
};

my $dir = '.';
my ($fh, $filename) = tempfile('tXXXXXXX', DIR => $dir, UNLINK => 1 );
my $f_dir = dirname $filename;
my $table = basename $filename;
binmode(DATA);
while(<DATA>){
  print $fh $_;
}
close($fh);

package Test::DB;
use base 'Class::DBI::AutoIncrement::Simple';
__PACKAGE__->connection("DBI:CSV:f_dir=$f_dir;csv_eol=\n");
__PACKAGE__->table($table);
__PACKAGE__->columns(Primary => qw/ my_id /);
__PACKAGE__->columns(Essential => qw/ first_name last_name / );

package main;

my $method;
$method = 'create' if Class::DBI->can('create');
$method = 'insert' if Class::DBI->can('insert');
ok($method,"got method: $method");

my $row = Test::DB->retrieve(3);
ok($row, "got row");
is($row->my_id,3,"got id");
is($row->first_name,'david',"got first");
is($row->last_name,'westbrook',"got last");

$row = Test::DB->$method({my_id=>5, first_name=>'aaa', last_name=>'bbbb'});
ok($row, "got row");
is($row->my_id,5,"got id");
is($row->first_name,'aaa',"got first");
is($row->last_name,'bbbb',"got last");

$row = Test::DB->$method({first_name=>'AAA', last_name=>'BBBB'});
ok($row, "got row");
is($row->my_id,6,"got auto-inc'd id");
is($row->first_name,'AAA',"got first");
is($row->last_name,'BBBB',"got last");

$row = Test::DB->retrieve(6);
ok($row, "got row");
is($row->my_id,6,"got auto-inc'd id");
is($row->first_name,'AAA',"got first");
is($row->last_name,'BBBB',"got last");

Test::DB->retrieve_all->delete_all;
my @rows = Test::DB->retrieve_all;
is(scalar(@rows),0,"all deleted");

$row = Test::DB->$method({first_name=>'AAA', last_name=>'BBBB'});
ok($row, "got row");
is($row->my_id,1,"got auto-inc'd id");
is($row->first_name,'AAA',"got first");
is($row->last_name,'BBBB',"got last");

__DATA__
my_id,first_name,last_name
3,david,westbrook
