use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok 'CGI::Simple::Header';
}

my $header = CGI::Simple::Header->new;

isa_ok $header->query, 'CGI::Simple';
