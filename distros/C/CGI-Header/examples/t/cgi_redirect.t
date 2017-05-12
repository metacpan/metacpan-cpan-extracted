use strict;
use warnings;
use Test::More tests => 7;
use Test::Output;

BEGIN {
    use_ok 'CGI::Redirect';
}

my $redirect = CGI::Redirect->new;

my %data = (
    '-Content_Type' => 'type',
    '-Cookie'       => 'cookies',
    '-URI'          => 'location',
    '-URL'          => 'location',
);

while ( my ($input, $expected) = each %data ) {
    is $redirect->_normalize($input), $expected;
}

is $redirect->location('http://somewhere.else/in/movie/land'), $redirect;

stdout_like { $redirect->finalize } qr{Status: 302 Found};
