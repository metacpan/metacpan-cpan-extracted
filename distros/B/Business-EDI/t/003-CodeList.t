#!/usr/bin/perl
#
# run this script with a true argument to get verbose output

use strict; use warnings;

use Test::More tests => 48;
use vars qw/$verbose $var1 $var2 $var3/;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('Business::EDI');
    use_ok('Business::EDI::CodeList');
    $verbose = @ARGV ? shift : 0;
    $Business::EDI::CodeList::verbose = $verbose;
}

my %data = (
#   num  => name
    1159 => "SequenceIdentifierSourceCode",
    1225 => "MessageFunctionCode",
    1227 => "CalculationSequenceCode",
);

my %values = (
    1159 => 1,  # Broadcast 1
    1225 => 28, # Accepted, with amendment in heading section
    1227 => 5,  # Fifth step of calculation
);

my %labels = (
    1159 => 'Broadcast 1',
    1225 => 'Accepted, with amendment in heading section',
    1227 => 'Fifth step of calculation',
);

my %descs = (
    1159 => 'Report from workstation 1.',
    1225 => 'Message accepted but amended in heading section.',
    1227 => 'Code specifying the fifth step of a calculation.',
);

$Data::Dumper::Indent = 1;

$verbose and print "data: ", Dumper(\%data);

foreach (sort keys %data) {
    note "#" x 60;
    ok($var1 = Business::EDI::CodeList->new_codelist($_),
              "Business::EDI::CodeList->new_codelist($_)"       );
    ok($var2 = Business::EDI::CodeList->new_codelist($data{$_}),
              "Business::EDI::CodeList->new_codelist($data{$_})");
    is_deeply($var1, $var2, "new_codelist($_) === new_codelist($data{$_})");

    ok($var1 = Business::EDI::CodeList->new_codelist($_, $values{$_}),
              "Business::EDI::CodeList->new_codelist($_, $values{$_})");
    ok($var2 = Business::EDI::CodeList->new_codelist($data{$_}, $values{$_}),
              "Business::EDI::CodeList->new_codelist($data{$_}, $values{$_})");
    is($var1->value, $values{$_}, "->value accessor");
    is($var1->label, $labels{$_}, "->label accessor");
    is($var1->desc,   $descs{$_}, "->desc  accessor");
    is_deeply($var1, $var2, "new_codelist($_, $values{$_}) === new_codelist($data{$_}, $values{$_})");
#   check deeply BEFORE setting new values

    my $newval = 'Some_New_Text';
    $var1->desc($newval);
    $var1->label($newval);
    is($var1->label, $newval, "->label accessor(write)");
    is($var1->desc,  $newval, "->desc  accessor(write)");

    ok($var3 = Business::EDI::CodeList->new_codelist($_, 'Nonsense'),
              "Business::EDI::CodeList->new_codelist($_, 'Nonsense') -- bad value");
    ok(not($var3->desc),  "No description for Nonsense value");
    ok(not($var3->label), "No label for Nonsense value");
    is($var3->value, 'Nonsense', "Nonsense value preserved");
}

note("done.");

