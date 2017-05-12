#!/usr/bin/perl
#

use strict; use warnings;

use Data::Dumper;
use Test::More tests => 8;

BEGIN {
    use_ok('Business::EDI');
    use_ok('Business::EDI::CodeList');
    use_ok('Business::EDI::Segment::BGM');
}

my $data = {
    '1004' => '582830',
    '4343' => 'AC',
    '1225' => '29',
    'C002' => {
        '1001' => '231'
    }
};

my $debug = @ARGV ? shift : 0;

$Business::EDI::debug = 
$Business::EDI::Spec::debug = $debug;
$Data::Dumper::Indent = 1;

my ($edi, $bgm1, $bgm2, $spec, $seg_spec);
ok($edi  = Business::EDI->new(version => 'd08a'),   "Business::EDI->new(version => 'd08a')");
ok($spec = $edi->spec,                              "edi->spec");
ok($seg_spec = $spec->get_spec('segment'),          "spec->get_spec('segment')");
ok($bgm1 = Business::EDI::Segment::BGM->new($data), "Business::EDI::Segment::BGM->new(...) # deprecated");
ok($bgm2 = $edi->segment('bgm', $data),             "edi->segment('BGM', ...)");
# is_deeply($bgm2, $bgm1, "BGM objects");

$debug and print "BGM1: ", Dumper($bgm1);
$debug and print "BGM2: ", Dumper($bgm2);
# print "\nBGM spec: ", Dumper($seg_spec->{BGM});
