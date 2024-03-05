use Test::More;

use File::Basename;

my $class = 'Business::ISBN::Data';
use_ok $class;

my @subs = qw(
	isbn_data_source
	);

can_ok 'Business::ISBN', @subs;

subtest 'source' => sub {
	ok exists $Business::ISBN::country_data{'_source'}, 'country_data has _source';
	like $Business::ISBN::country_data{'_source'}, qr/RangeMessage\.xml/, 'source is RangeMessage';
	is Business::ISBN::isbn_data_source(), $Business::ISBN::country_data{'_source'}, 'isbn_data_source returns _source';

	delete local $Business::ISBN::country_data{'_source'};
	unlike $Business::ISBN::country_data{'_source'}, qr/RangeMessage\.xml/, 'source is not RangeMessage';
	is basename( Business::ISBN::isbn_data_source() ), 'Data.pm', 'source is module';
	};

done_testing();
