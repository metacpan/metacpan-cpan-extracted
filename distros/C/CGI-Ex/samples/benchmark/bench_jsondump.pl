#!/usr/bin/perl -w

# As of JSON switch to 2.0 and new JSON interface
# Benchmark: running cejd, json, zejd for at least 2 CPU seconds...
#       cejd:  3 wallclock secs ( 2.17 usr +  0.00 sys =  2.17 CPU) @ 7078.34/s (n=15360)
#       json:  3 wallclock secs ( 2.24 usr +  0.00 sys =  2.24 CPU) @ 8723.21/s (n=19540)
#       zejd:  3 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 7111.11/s (n=15360)
#        Rate cejd zejd json
# cejd 7078/s   --  -0% -19%
# zejd 7111/s   0%   -- -18%
# json 8723/s  23%  23%   --
#
# Benchmark: running cejd, json for at least 2 CPU seconds...
#       cejd:  3 wallclock secs ( 2.08 usr +  0.00 sys =  2.08 CPU) @ 5800.48/s (n=12065)
#       json:  2 wallclock secs ( 2.13 usr +  0.00 sys =  2.13 CPU) @ 7206.57/s (n=15350)
#        Rate cejd json
# cejd 5800/s   -- -20%
# json 7207/s  24%   --
#
# Benchmark: running cejd, json for at least 2 CPU seconds...
#       cejd:  2 wallclock secs ( 2.06 usr +  0.00 sys =  2.06 CPU) @ 30656.31/s (n=63152)
#       json:  2 wallclock secs ( 2.08 usr +  0.00 sys =  2.08 CPU) @ 24666.35/s (n=51306)
#         Rate json cejd
# json 24666/s   -- -20%
# cejd 30656/s  24%   --



use strict;

use Benchmark qw(cmpthese timethese);
use JSON;
use CGI::Ex::JSONDump;

my $json = JSON->new;
$json->canonical(1);
#$json->pretty;
my $cejd = CGI::Ex::JSONDump->new;


my $data = {
    one   => 'two',
    three => [qw(a b c)],
    four  => 1,
    five  => '1.0',
    six   => undef,
};

print "JSON\n--------------------\n". $json->encode($data)."\n----------------------------\n";
print "CEJD\n--------------------\n". $cejd->dump($data)     ."\n----------------------------\n";

cmpthese timethese(-2, {
    json => sub { my $a = $json->encode($data) },
    cejd => sub { my $a = $cejd->dump($data) },
    zejd => sub { my $a = $cejd->dump($data) },
});

###----------------------------------------------------------------###

$json = JSON->new;
$json->canonical(1);
$json->pretty;
$cejd = CGI::Ex::JSONDump->new({pretty => 1});

$data = {
    one   => 'two',
    three => [qw(a b c)],
    four  => 1,
    five  => '1.0',
    six   => '12345678901234567890',
    seven => undef,
};

print "JSON\n--------------------\n". $json->encode($data)."\n----------------------------\n";
print "CEJD\n--------------------\n". $cejd->dump($data)     ."\n----------------------------\n";

cmpthese timethese(-2, {
    json => sub { my $a = $json->encode($data) },
    cejd => sub { my $a = $cejd->dump($data) },
});

###----------------------------------------------------------------###

$json = JSON->new;
$json->canonical(1);
$json->pretty;
$cejd = CGI::Ex::JSONDump->new({pretty => 1, no_tag_splitting => 1});

$data = ["foo\n<script>\nThis is sort of \"odd\"\n</script>"];

print "JSON\n--------------------\n". $json->encode($data)."\n----------------------------\n";
print "CEJD\n--------------------\n". $cejd->dump($data)     ."\n----------------------------\n";

cmpthese timethese(-2, {
    json => sub { my $a = $json->encode($data) },
    cejd => sub { my $a = $cejd->dump($data) },
});
