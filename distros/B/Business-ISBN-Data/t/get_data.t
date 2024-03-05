use Test::More;

use File::Basename;

my $class = 'Business::ISBN::Data';
use_ok $class;

my @subs = qw(
	_get_data
	);

can_ok $class, @subs;

subtest 'ISBN_RANGE_MESSAGE exists' => sub {
	my $file = 'lib/Business/ISBN/RangeMessage.xml';
	ok -e $file, "$file exists";
	local $ENV{ISBN_RANGE_MESSAGE} = $file;

	my %data = Business::ISBN::Data->_get_data();
	ok exists $data{'_source'}, '_source exists in hash';
	is $data{'_source'}, $file, '_source is the file';
	};

subtest 'ISBN_RANGE_MESSAGE does not exist' => sub {
	my $file = 'lib/Business/ISBN/RangeMessage.yaml';
	ok ! -e $file, "$file does not exist";
	local $ENV{ISBN_RANGE_MESSAGE} = $file;

	diag( "This will be a warning here" );
	my %data = Business::ISBN::Data->_get_data();
	diag( "There should be no more warnings" );
	ok exists $data{'_source'}, '_source exists in hash';
	is basename($data{'_source'}), 'RangeMessage.xml', '_source is distributed file';
	};

done_testing();
