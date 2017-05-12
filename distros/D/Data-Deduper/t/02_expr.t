use strict;
use warnings;
use Test::More tests => 2;
use Data::Deduper;

my @data = (
	{ title => "google", link => "http://www.google.com" },
	{ title => "facebook", link => "http://www.facebook.com" },
	{ title => "twitter", link => "http://www.twitter.com" },
);

my $dd = Data::Deduper->new(
	expr => sub {
			my ($a, $b) = @_;
			$a->{link} eq $b->{link};
		},
	data => \@data,
);

my @newer = (
	{ title => "google news", link => "http://www.google.com" },
);

is_deeply([$dd->dedup(\@newer)], [], 'dedup');
is_deeply([$dd->data], [@data], 'data');
