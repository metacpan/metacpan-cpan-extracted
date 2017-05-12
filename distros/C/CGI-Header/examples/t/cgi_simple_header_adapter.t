use strict;
use warnings;
use Test::MockTime qw/set_fixed_time/;
use Test::More tests => 3;

set_fixed_time( 1341637509 );

BEGIN {
    use_ok 'CGI::Simple::Header::Adapter';
}

my $header = CGI::Simple::Header::Adapter->new;

$header->query->no_cache(1);

is_deeply $header->as_arrayref, [
    'Expires',      'Sat, 07 Jul 2012 05:05:09 GMT',
    'Date',         'Sat, 07 Jul 2012 05:05:09 GMT',
    'Pragma',       'no-cache',
    'Content-Type', 'text/html; charset=ISO-8859-1',
];

is $header->as_string, $header->query->header;
