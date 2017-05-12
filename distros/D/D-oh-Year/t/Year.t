#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

BEGIN { use_ok "D'oh::Year"; }

# Make sure the curtain is up.
is_deeply([localtime], [CORE::localtime]);
is_deeply([gmtime],    [CORE::gmtime]);


# Make sure we're getting objects.
ok( ref +(localtime)[5] );
ok( ref +(gmtime)[5] );


my @bad_code = (
				q|"19$year"|,
				q|"20$year"|,
				q|"200$year"|,
				q|"Foo 19$year"|,
				q|"Foo 20$year"|,
				q|"Foo 200$year"|,
				q|'19'.$year|,
				q|'20'.$year|,
				q|'200'.$year|,
				q|$year -= 100|,
				q|$year = $year - 100|,
#				q|sprintf "19%02d", $year|,
#				q|sprintf "20%02d", $year|,
			   );

my @good_code = (
				 q|"${year}19"|,
				 q|"${year}20"|,
				 q|"19 $year"|,
				 q|"20 $year"|,
				 q|1900+$year|,
				 q|$year+1900|,
				 q|$year -= 999|,
				 q|$year = $year - 20938|,
				);

my $test_code = <<'END_OF_CODE';
foreach my $year ((localtime)[5], (gmtime)[5]) {
	foreach my $c (@bad_code) {
		() = eval $c;
		::like($@, qr/year/i);
		::like($@, qr/$Error/i);
	}
		
	foreach my $c (@good_code) {
		() = eval $c;
		::is($@, '');
	}
}
END_OF_CODE

my $Error = '';
eval $test_code;

package D'oh::Year::Test::Warn;

use D'oh::Year qw(:WARN);

$SIG{__WARN__} = sub { die join('', 'WARN:',@_) };
$Error = '^WARN:';
eval $test_code;


package D'oh::Year::Test::y2k;

use y2k;

$Error = '';
eval $test_code;
