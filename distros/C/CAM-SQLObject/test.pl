#!/usr/bin/perl -w

use warnings;
use strict;

BEGIN
{ 
   use Test::More tests => 7;
   use_ok("CAM::SQLObject");
}

# Make some trivial subclasses for inheritance/performance testing

package this::test1;
our @ISA = qw(CAM::SQLObject);
package this::test2;
our @ISA = qw(this::test1);
package this::test3;
our @ISA = qw(this::test2);
sub renderf8
{
   my $self = shift;
   return $self->getf8() + 0;
}
package this::test4;
our @ISA = qw(this::test3);

package main;

my $loops = 1000;
my $start;
my $stop;
my %get;
my %render;
my $obj;

my %fields = (
              id => 1,
              date => "2003-03-10",
              num => 50,
              map({("f$_",$_+0)} 1..19),
              );

# package this::test defined below
$obj = this::test4->new();
#$obj = CAM::SQLObject->new();
ok($obj, "new");

$obj->set($_, $fields{$_}) foreach (keys %fields);
is($obj->renderid(), $fields{id}, "set/renderid");

$obj->renderAllFields(); # warm up the evals

$start = &getTime();
%get = $obj->getAllFields() for (1..$loops);
$stop = &getTime();
is_deeply(\%get, \%fields, "getAllFields (".($stop-$start)." seconds per $loops)");

$start = &getTime();
%render = $obj->renderAllFields() for (1..$loops);
$stop = &getTime();
is_deeply(\%render, \%fields, "renderAllFields (".($stop-$start)." seconds per $loops)");

is(CAM::SQLObject->_getDBH(), undef, "_getDBH");
my $fakedbh = bless({"dumb test" => "true"}, "DBI");
CAM::SQLObject->setDBH($fakedbh);
is_deeply(CAM::SQLObject->_getDBH(), $fakedbh, "_getDBH");

exit;

sub getTime
{
   my($user,$system,$cuser,$csystem)=times;
   return $user+$system+$cuser+$csystem;
}

