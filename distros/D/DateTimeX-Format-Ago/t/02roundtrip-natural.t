use strict;
use warnings;
use Test::More;
use DateTimeX::Format::Ago;

plan skip_all => 'Need DateTime::Format::Natural'
	unless eval 'use DateTime::Format::Natural; 1';

plan tests => 13;
my $tests = <<'TESTS';
just now
a minute ago
3 minutes ago
an hour ago
3 hours ago
a day ago
3 days ago
a week ago
3 weeks ago
a month ago
3 months ago
a year ago
3 years ago
TESTS

my $natural = DateTime::Format::Natural->new;
my $ago     = DateTimeX::Format::Ago->new(language => 'en-GB-oed');
foreach my $string (split /\n/, $tests)
{
	next unless length $string;
	
	SKIP: {
		my $dt = $natural->parse_datetime($string);
		skip "DateTime::Format::Natural couldn't parse '$string'", 1
			unless $natural->success;
		
		is($ago->format_datetime($dt), $string, "Roundtrip for '$string'");
	};
}
