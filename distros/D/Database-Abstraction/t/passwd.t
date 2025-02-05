#!perl -w

# Test /etc/passwd as a database

use strict;

use lib 't/lib';

use Test::Most;

if(-r '/etc/passwd') {
	plan(tests => 4);

	use_ok('MyLogger');
	use_ok('Database::passwd');

	my $passwd = Database::passwd->new({ directory => '/etc', filename => 'passwd', no_entry => 1, logger => MyLogger->new() });
	my $row = $passwd->fetchrow_hashref(name => 'root');

	cmp_ok($row->{'uid'}, '==', 0, 'Root has UID 0');

	diag(Data::Dumper->new([$row])->Dump()) if($ENV{'TEST_VERBOSE'});

	cmp_ok($passwd->uid({ name => 'root' }), '==', 0, 'AUTOLOAD works');
} else {
	plan(skip_all => 'Needs /etc/passwd to test');
}
