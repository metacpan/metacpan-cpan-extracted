use Test::More;

use File::Basename;

my $class = 'Business::ISBN::Data';
use_ok $class;

my @subs = qw(
	_parse_range_message
	);

can_ok $class, @subs;

subtest 'file does not exist' => sub {
	my $file = 'lib/Business/ISBN/RangeMessage.yamml';
	ok ! -e $file, "$file does not exist";

	diag( "This will be a warning here" );
	my $result = Business::ISBN::Data::_parse_range_message( $file );
	diag( "There should be no more warnings" );
	ok ! defined $result, "_parse_range_message returns undef if file does not exist";
	};

done_testing();
