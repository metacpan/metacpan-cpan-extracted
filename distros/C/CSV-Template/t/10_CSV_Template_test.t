#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN { 
    use_ok('CSV::Template');
}

can_ok("CSV::Template", 'new');

my $csv = CSV::Template->new(filename => "t/test.tmpl");
isa_ok($csv, "CSV::Template");

can_ok($csv, 'quote_string'); 
can_ok($csv, 'param'); 

$csv->param(title => $csv->quote_string('This is a test, "title"'));
$csv->param(test_loop => [
                        { one => 1, two => 2, three => 3 },
                        { one => 2, two => 4, three => 6 },
                        { one => 3, two => 6, three => 9 },                                                
                        ]);

can_ok($csv, 'output');
my $output = $csv->output();

my $expected = <<EXPECTED;
"This is a test, ""title""",
,
1,2,3,
2,4,6,
3,6,9,
,
EXPECTED
chomp $expected;

is($output, $expected, '... got what we expected');
