use strict;
use warnings;
use Test::More;
use DateTimeX::Format::Ago;

eval { require Time::HiRes; 1 }
	or plan skip_all => "Need Time::HiRes for this test";

plan tests => 1;

my $now = DateTime->from_epoch(epoch => scalar Time::HiRes::time());

unlike(
	DateTimeX::Format::Ago->new(language => 'en')->format_datetime($now),
	qr{future}i,
);
