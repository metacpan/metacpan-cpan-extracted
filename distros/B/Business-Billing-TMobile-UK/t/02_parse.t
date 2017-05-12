use Test::More tests => 1;

use Business::Billing::TMobile::UK;

$site = Business::Billing::TMobile::UK->new(username => 'mrman', password => 'xxx');
my $test_file = 't/test.html';
my $content = '';

{ 
	local $/ = undef;
	open $fh, '<', $test_file or die("Could not open $test_file: $!\n");
	$content = <$fh>;
	close $fh;
}

my $ra_allowances = $site->_parse_allowances($content);
$ra_allowances = [] unless ref $ra_allowances;
my $ra_expected = ['137 minutes', '100 texts'];

ok(eq_array($ra_allowances, $ra_expected), 'Allowances Page Correctly Parsed');
