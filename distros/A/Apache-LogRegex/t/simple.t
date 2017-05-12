#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('Apache::LogRegex');

my $format = '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"';
my @fields = qw/%h %l %u %t %r %>s %b %{Referer}i %{User-Agent}i/;
my $regex;
{
    my $inner_regex = qr/"([^"\\]*(?:\\.[^"\\]*)*)"/;
    $regex = qr/^(\S*)\s(\S*)\s(\S*)\s(\[[^\]]+\])\s$inner_regex\s(\S*)\s(\S*)\s$inner_regex\s+$inner_regex\s*$/;
}
my $line1  = '212.74.15.68 - - [23/Jan/2004:11:36:20 +0000] "GET /images/previous.png HTTP/1.1" 200 2607 "http://peterhi.dyndns.org/bandwidth/index.html" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202"';
my %record1 = (
    '%h' => '212.74.15.68',
    '%l' => '-',
    '%u' => '-',
    '%t' => '[23/Jan/2004:11:36:20 +0000]',
    '%r' => 'GET /images/previous.png HTTP/1.1',
    '%>s' => '200',
    '%b' => '2607',
    '%{Referer}i' => 'http://peterhi.dyndns.org/bandwidth/index.html',
    '%{User-Agent}i' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202',
);

my $line2  = '212.74.15.68 - - [23/Jan/2004:11:36:20 +0000] "GET /images/previous.png=\" HTTP/1.1" 200 2607 "http://peterhi.dyndns.org/bandwidth/index.html" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202"' . "\n";
my %record2 = (
    '%h' => '212.74.15.68',
    '%l' => '-',
    '%u' => '-',
    '%t' => '[23/Jan/2004:11:36:20 +0000]',
    '%r' => 'GET /images/previous.png=\" HTTP/1.1',
    '%>s' => '200',
    '%b' => '2607',
    '%{Referer}i' => 'http://peterhi.dyndns.org/bandwidth/index.html',
    '%{User-Agent}i' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202',
);

my $line3  = '4.224.234.46 - - [20/Jul/2004:13:18:55 -0700] "GET /core/listing/pl_boat_detail.jsp?&units=Feet&checked_boats=1176818&slim=broker&&hosturl=giffordmarine&&ywo=giffordmarine& HTTP/1.1" 200 2888 "http://search.yahoo.com/bin/search?p=\"grady%20white%20306%20bimini\"" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; YPC 3.0.3; yplus 4.0.00d)"' . "\r\n";
my %record3 = (
    '%h' => '4.224.234.46',
    '%l' => '-',
    '%u' => '-',
    '%t' => '[20/Jul/2004:13:18:55 -0700]',
    '%r' => 'GET /core/listing/pl_boat_detail.jsp?&units=Feet&checked_boats=1176818&slim=broker&&hosturl=giffordmarine&&ywo=giffordmarine& HTTP/1.1',
    '%>s' => '200',
    '%b' => '2888',
    '%{Referer}i' => 'http://search.yahoo.com/bin/search?p=\"grady%20white%20306%20bimini\"',
    '%{User-Agent}i' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; YPC 3.0.3; yplus 4.0.00d)',
);

my $line4  = '212.74.15.68 - - [23/Jan/2004:11:36:20 +0000] "GET /images/previous.png=\" HTTP/1.1" 200 2607 "http://peterhi.dyndns.org/bandwidth/index.html"   "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202"';
my %record4 = (
    '%h' => '212.74.15.68',
    '%l' => '-',
    '%u' => '-',
    '%t' => '[23/Jan/2004:11:36:20 +0000]',
    '%r' => 'GET /images/previous.png=\" HTTP/1.1',
    '%>s' => '200',
    '%b' => '2607',
    '%{Referer}i' => 'http://peterhi.dyndns.org/bandwidth/index.html',
    '%{User-Agent}i' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202',
);

my $line5  = ' - - [23/Jan/2004:11:36:20 +0000] "GET /images/previous.png=\" HTTP/1.1" 200  "http://peterhi.dyndns.org/bandwidth/index.html"   "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202"';
my %record5 = (
    '%h' => '',
    '%l' => '-',
    '%u' => '-',
    '%t' => '[23/Jan/2004:11:36:20 +0000]',
    '%r' => 'GET /images/previous.png=\" HTTP/1.1',
    '%>s' => '200',
    '%b' => '',
    '%{Referer}i' => 'http://peterhi.dyndns.org/bandwidth/index.html',
    '%{User-Agent}i' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202',
);

my $line6  = '212.74.15.68 - -  "GET /images/previous.png=\" HTTP/1.1" 200 2607 "http://peterhi.dyndns.org/bandwidth/index.html"   "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2) Gecko/20021202"';

################################################################################
# Create a new object
################################################################################

eval { Apache::LogRegex->new(); };
like( $@, qr/^Apache::LogRegex->new\(\) takes 1 argument/, 'Wrong number of arguments' );

eval { Apache::LogRegex->new(1,2); };
like( $@, qr/^Apache::LogRegex->new\(\) takes 1 argument/, 'Wrong number of arguments' );

eval { Apache::LogRegex->new(undef); };
like( $@, qr/^Apache::LogRegex->new\(\) argument 1 \(FORMAT\) is false/, 'Undefined argument' );

eval { Apache::LogRegex->new(""); };
like( $@, qr/^Apache::LogRegex->new\(\) argument 1 \(FORMAT\) is false/, 'False argument' );

my $x = Apache::LogRegex->new($format);
isa_ok( $x, 'Apache::LogRegex' );

################################################################################
# Check the fields and regex
################################################################################

my @l = $x->names();
isa_ok( \@l, 'ARRAY');

is(scalar(@fields), scalar(@l), 'Same length');
is(join(' ', @fields), join(' ', @l), 'Same fields');

eval { $x->names(1); };
like($@, qr/^Apache::LogRegex->names\(\) takes no argument/, 'Wrong number of arguments');

my $r = $x->regex();
is($r, $regex, 'Regex matches');

eval { $x->regex(1); };
like($@, qr/^Apache::LogRegex->regex\(\) takes no argument/, 'Wrong number of arguments');

################################################################################
# Check it can parse a line
################################################################################

my @data = $x->parse($line1);
is_deeply(\%record1, { @data }, 'Line 1 parsed OK');

################################################################################
# Check it can parse a line with a \" in it
################################################################################

@data = $x->parse($line2);
is_deeply(\%record2, { @data }, 'Line 2 parsed OK');

################################################################################
# Check it can parse a line with a \" in the referer
################################################################################

@data = $x->parse($line3);
is_deeply(\%record3, { @data }, 'Line 3 parsed OK');

################################################################################
# Check it can parse a line with an extra space between some elements
################################################################################

@data = $x->parse($line4);
is_deeply(\%record4, { @data }, 'Line 4 parsed OK');

################################################################################
# Check it can parse a line and return a hashref
################################################################################

my $data = $x->parse($line1);
is_deeply(\%record1, $data, 'Line 1 parsed OK to hashref');

################################################################################
# Check it does not parse junk
################################################################################

my %data = $x->parse('dummy');
cmp_ok(%data, '==', 0, 'Does not parse junk in list context');

$data = $x->parse('dummy');
ok(! defined $data, 'Does not parse junk in scalar context');

eval { %data = $x->parse(); };
like($@, qr/^Apache::LogRegex->parse\(\) takes 1 argument/, 'Wrong number of arguments');

eval { %data = $x->parse(1,2); };
like($@, qr/^Apache::LogRegex->parse\(\) takes 1 argument/, 'Wrong number of arguments');

eval { %data = $x->parse(undef); };
like($@, qr/^Apache::LogRegex->parse\(\) argument 1 \(LINE\) is undefined/, 'Wrong number of arguments');

################################################################################
# Check it can parse a line
################################################################################

my $parser = $x->generate_parser;
isa_ok( $parser, 'CODE' );

$data = $parser->($line1);
is_deeply(\%record1, $data, 'Line 1 parsed OK by closure');

my $data2 = $parser->($line2);

ok($data != $data2, 'New record');

$parser = $x->generate_parser(reuse_record => 1);
isa_ok( $parser, 'CODE' );

$data = $parser->($line1);
isa_ok( $data, 'HASH');

$data2 = $parser->($line2);

ok($data == $data2, 'Reused record');

$data = $parser->(substr($line1, 0, length($line1)/2));
ok(! defined($data), "undef for empty string");

$data = $parser->("");
ok(! defined($data), "undef for empty string");

$data = $parser->(undef);
ok(! defined($data), "undef for undef");

$data = $parser->($line5);
is_deeply(\%record5, $data, 'Line 5 parsed OK');

$data = $parser->($line6);
ok(not(defined($data)), 'Line 6 does not parse due to missing required field');

done_testing;
