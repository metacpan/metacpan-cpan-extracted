use Test::More tests => 1;
use Acme::RunDoc;

our $test_result = 0;

(my $file = __FILE__)
	=~ s{ 02do.t }{ 'test-file.doc' }ex;

Acme::RunDoc->do($file);

ok $test_result or diag $file;
