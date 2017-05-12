use utf8;
use Test::Most;
use DateTime::Format::Czech;
use DateTime;

sub gives($$$) {
    my ($formatter, $args, $expected) = @_;
    is $formatter->format_datetime(DateTime->new(%$args)), $expected;
}

{
    my $f = DateTime::Format::Czech->new;
    gives $f, {year=>2010, month=> 1, day=>1}, '1. ledna';
    gives $f, {year=>2010, month=>12, day=>1}, '1. prosince';
    gives $f, {year=>2010, month=>10, day=>5}, '5. října';
}{
    my $f = DateTime::Format::Czech->new(show_year => 1);
    gives $f, {year=>2010, month=> 1, day=>1}, '1. ledna 2010';
}{
    my $f = DateTime::Format::Czech->new(show_year => 1, show_month_name => 0);
    gives $f, {year=>2010, month=> 1, day=>1}, '1. 1. 2010';
}

done_testing;
