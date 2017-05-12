# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 3;

use Class::Colon Person => [ qw(first middle last) ];

package main;

#_______ Test objectify one string _____
my $data_l = [ "Phil:David:Crow", "Lisa:Dianne:Crow" ];
my $data   = $data_l->[0];
my $person = Person->OBJECTIFY($data);
my $string = $person->STRINGIFY();
is($string, $data_l->[0], "STRINGIFY");

my $list = [ $person, Person->OBJECTIFY($data_l->[1]) ];
open OUTPUT, ">t/output";
Person->WRITE_HANDLE(*OUTPUT, $list);
close OUTPUT;

open OUTPUT, "t/output";
chomp(my @records = <OUTPUT>);
close OUTPUT;

is_deeply(\@records, $data_l, "WRITE_HANDLE");

unlink "t/output";

Person->WRITE_FILE("t/output.again", $list);

open OUTPUT, "t/output.again" or die "File t/output.again not written";
chomp(my @records = <OUTPUT>);
close OUTPUT;

is_deeply(\@records, $data_l, "WRITE_FILE");

unlink "t/output.again";
