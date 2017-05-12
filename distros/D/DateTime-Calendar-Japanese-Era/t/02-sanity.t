#!perl
use strict;
use Test::More (tests => 11);
use utf8;

BEGIN
{
    use_ok("DateTime::Calendar::Japanese::Era", qw(SOUTH_REGIME NORTH_REGIME) );
}

my $class = 'DateTime::Calendar::Japanese::Era';
my @eras =(
    $class->lookup_by_date(datetime => DateTime->new(year => 1990)),
);
push @eras, $class->lookup_by_name(name => '平成');
    
foreach my $e (@eras) {
    isa_ok($e, 'DateTime::Calendar::Japanese::Era');
    ok($e->start->compare( DateTime->new(year => 1989, month => 1,  day => 8, time_zone => 'Asia/Tokyo')) == 0);
    ok($e->end->compare( DateTime::Infinite::Future->new() ) == 0);
    is($e->id, 'HEISEI');
    is($e->name, '平成');
}


