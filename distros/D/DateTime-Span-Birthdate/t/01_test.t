use strict;
use t::TestBase;
use DateTime::Span::Birthdate;
plan tests => 2 * blocks;

run {
    my $block = shift;
    my $span = $block->age
        ? DateTime::Span::Birthdate->new(age => $block->age, on => $block->on)
        : DateTime::Span::Birthdate->new(from => $block->from, to => $block->to, on => $block->on);
    is $span->start, $block->start;
    is $span->end, $block->end;
};

__END__

===
--- age: 29
--- on: 2006-10-26
--- start: 1976-10-27
--- end:   1977-10-26

===
--- age: 20
--- on: 2000-11-11
--- start: 1979-11-12
--- end: 1980-11-11

===
--- from: 24
--- to: 25
--- on: 2001-12-8
--- start: 1975-12-09
--- end: 1977-12-08

===
--- age: 50
--- on: 2001-12-8
--- start: 1950-12-09
--- end: 1951-12-08

===
--- from: 50
--- to: 50
--- on: 2001-12-8
--- start: 1950-12-09
--- end: 1951-12-08

===
--- from: 50
--- to: 60
--- on: 2001-12-8
--- start: 1940-12-09
--- end: 1951-12-08

===
--- age: 20
--- on: 2001-12-31
--- start: 1981-01-01
--- end: 1981-12-31
