#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw/timethese cmpthese/;

use Apache::Log::Parser;
use ApacheLog::Parser qw/parse_line_to_hash/;

my $common = q{localhost.local - - [04/Oct/2007:12:34:56 +0900] "GET /index.html HTTP/1.1" 200 2326};
my $combined = q{localhost.local - - [04/Oct/2007:12:34:56 +0900] "GET /index.html HTTP/1.1" 200 2326 "http://www.google.com/" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.84 Safari/534.13"};
my $custom = q{localhost.local - - [04/Oct/2007:12:34:56 +0900] "GET /index.html HTTP/1.1" 200 2326 "http://www.google.com/" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.84 Safari/534.13" "localhost" "127.0.0.1201102081601001" "000-mobilehost.any" 1280};

my $default_fast = Apache::Log::Parser->new( fast => 1 );
my $common_fast = Apache::Log::Parser->new( fast => ['common'] );
my $custom_fast = Apache::Log::Parser->new( fast => [[qw(referer agent vhost usertrack mobileid request_duration)], 'combined', 'common'] );

my $default_strict = Apache::Log::Parser->new( strict => 1 );
my $common_strict = Apache::Log::Parser->new( strict => ['common'] );

my @customized_fields = qw( rhost logname user datetime request status bytes referer agent vhost usertrack mobileid request_duration );
my $custom_strict = Apache::Log::Parser->new( strict => [
    [" ", \@customized_fields, sub{my $x=shift;defined($x->{vhost}) and defined($x->{usertrack}) and defined($x->{mobileid})}],
    'combined',
    'common',
    'vhost_common'
]);
cmpthese(
    timethese(
        0,
        {
            common_regex => sub {
                my @values = ( $common =~ m!^([^\s]*)\s+([^\s]*)\s+([^\s]*)\s+\[([^: ]+):([^ ]+) ([-+0-9]+)\]\s+"(\w+) ([^\s]*) ([^\s]*)"\s+([^\s]*)\s+([^\s]*)! );
            },
            default_fast => sub { my $log = $default_fast->parse($common); },
            common_fast => sub { my $log = $common_fast->parse($common); },
            custom_fast => sub { my $log = $custom_fast->parse($common); },
            default_strict => sub { my $log = $default_strict->parse($common); },
            common_strict => sub { my $log = $common_strict->parse($common); },
            custom_strict => sub { my $log = $custom_strict->parse($common); },
        }
    )
);

cmpthese(
    timethese(
        0,
        {
            combined_regex => sub {
                my @values = ( $combined =~ m!^([^\s]*)\s+([^\s]*)\s+([^\s]*)\s+\[([^: ]+):([^ ]+) ([-+0-9]+)\]\s+"(\w+) ([^\s]*) ([^\s]*)"\s+([^\s]*)\s+([^\s]*)\s+"([^"]*)"\s+"([^"]*)"! );
            },
            apachelog_parser => sub { my %log = parse_line_to_hash($combined); },
            default_fast => sub { my $log = $default_fast->parse($combined); },
            custom_fast => sub { my $log = $custom_fast->parse($combined); },
            default_strict => sub { my $log = $default_strict->parse($combined); },
            custom_strict => sub { my $log = $custom_strict->parse($combined); },
        }
    )
);

cmpthese(
    timethese(
        0,
        {
            custom_regex => sub {
                my @values = ( $custom =~ m!^([^\s]*)\s+([^\s]*)\s+([^\s]*)\s+\[([^: ]+):([^ ]+) ([-+0-9]+)\]\s+"(\w+) ([^\s]*) ([^\s]*)"\s+([^\s]*)\s+([^\s]*)\s+"([^"]*)"\s+"([^"]*)"\s+"([^"]*)"\s+"([^"]*)"\s+"([^"]*)"\s+(\d+)! );
            },
            custom_regex2 => sub {
                my @values = ( $custom =~ m!^([^\s]*)\s+([^\s]*)\s+([^\s]*)\s+\[([^: ]+):([^ ]+) ([-+0-9]+)\]\s+"(\w+) ([^\s]*) ([^\s]*)"\s+([^\s]*)\s+([^\s]*)\s+"([^"]*)"\s+"([^"]*)"(\s+"([^"]*)")?(\s+"([^"]*)")?(\s+"([^"]*)")?(\s+(\d+))?! );
            },
            custom_fast => sub { my $log = $custom_fast->parse($custom); },
            custom_strict => sub { my $log = $custom_strict->parse($custom); },
        }
    )
);
