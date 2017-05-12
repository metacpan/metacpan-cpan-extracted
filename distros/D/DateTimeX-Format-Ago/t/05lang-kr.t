use strict;
use warnings;
use utf8;
use DateTimeX::Format::Ago;
use Test::More tests => 200;

# Some of these tests rely on computation being carried out reasonably fast.
# I can only see them failing on really slow and overloaded CPUs though.

my $ago = DateTimeX::Format::Ago->new(language => 'KO');

foreach my $unit (qw/years months weeks days hours minutes/)
{
	my $max = {
		years   => 25,
		months  => 11,
		weeks   => 3,  # don't want to fail tests in February 2013.
		days    => 6,
		hours   => 22, # don't want to fail due to daylight savings.
		minutes => 59,
	}->{$unit};
	
	my $when = DateTime->now->subtract($unit => 1);
	is($ago->format_datetime($when), {
		'years'    => '작년',
		'months'   => '지난달',
		'weeks'    => '지난주',
		'days'     => '어제',
		'hours'    => '1시간 전',
		'minutes'  => '1분 전',
	}->{$unit});
	
	my $deunit = {
		years    => '년 전',
		months   => '개월 전',
		weeks    => '주 전',
		days     => '일 전',
		hours    => '시간 전',
		minutes  => '분 전',
	}->{$unit};
	
	for my $n (2..$max)
	{
		my $when = DateTime->now->subtract($unit => $n);
		is($ago->format_datetime($when), "${n}${deunit}");
	}
}

for my $n (1..58)
{
	my $when = DateTime->now->subtract(seconds => $n);
	is($ago->format_datetime($when), "방금 전");
}

for my $n (62..70)
{
	my $when = DateTime->now->subtract(seconds => $n);
	is($ago->format_datetime($when), "1분 전");
}

for my $unit (qw/seconds minutes hours days weeks months years/)
{
	my $when = DateTime->now->add($unit => 3);
	is($ago->format_datetime($when), "잠시 후");
}
