#!perl

use 5.006;
use strict; use warnings;
use CPAN::Search::Tester;
use Test::More tests => 4;

eval { CPAN::Search::Tester->new()->search() };
like($@, qr/ERROR: Invalid ID or GUID received/);

eval { CPAN::Search::Tester->new()->search('ABCD') };
like($@, qr/ERROR: Invalid ID or GUID received/);

eval { CPAN::Search::Tester->new()->search(id => 'ABCD') };
like($@, qr/ERROR: Invalid ID or GUID received/);

eval { CPAN::Search::Tester->new()->search(guid => 'ABCD') };
like($@, qr/ERROR: Invalid ID or GUID received/);
