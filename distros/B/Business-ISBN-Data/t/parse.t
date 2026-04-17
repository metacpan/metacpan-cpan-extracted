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

	my $warning;
	local $SIG{'__WARN__'} = sub { $warning .= $_[0] };
	my $result = Business::ISBN::Data::_parse_range_message( $file );
	like $warning, qr/Could not open/, 'warning message notes the file is not there';
	ok ! defined $result, "_parse_range_message returns undef if file does not exist";
	};

done_testing();
