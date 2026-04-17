use Test::More;

use File::Basename;

my $class = 'Business::ISBN::Data';
use_ok $class;

my @subs = qw(
	_get_data
	);

can_ok $class, @subs;

my $KEY = 'ISBN_RANGE_MESSAGE';

# https://github.com/briandfoy/business-isbn-data/issues/236
subtest 'ISBN_RANGE_MESSAGE env var does not exist before or after' => sub {
	delete local $ENV{$KEY};
	ok ! exists $ENV{$KEY}, "env var key <$KEY> does not exist (before)";
	my %data = Business::ISBN::Data->_get_data();
	ok ! exists $ENV{$KEY}, "env var key <$KEY> does not exist (after)";
	};

subtest 'ISBN_RANGE_MESSAGE file exists' => sub {
	my $file = 'lib/Business/ISBN/RangeMessage.xml';
	ok -e $file, "$file exists";
	local $ENV{$KEY} = $file;

	my %data = Business::ISBN::Data->_get_data();
	ok exists $data{'_source'}, '_source exists in hash';
	is $data{'_source'}, $file, '_source is the file';
	};

subtest 'ISBN_RANGE_MESSAGE file does not exist' => sub {
	my $file = 'lib/Business/ISBN/RangeMessage.yaml';
	ok ! -e $file, "$file does not exist";
	local $ENV{$KEY} = $file;

	my $warning;
	local $SIG{'__WARN__'} = sub { $warning .= $_[0] };
	my %data = Business::ISBN::Data->_get_data();
	like $warning, qr/does not exist/, 'warning message notes the file is not there';
	ok exists $data{'_source'}, '_source exists in hash';
	is basename($data{'_source'}), 'RangeMessage.xml', '_source is distributed file';
	};

done_testing();
