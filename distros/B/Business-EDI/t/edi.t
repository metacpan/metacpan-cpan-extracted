#!/usr/bin/perl
#

use strict; use warnings;

use Data::Dumper;
use Test::More tests => 39;

BEGIN {
    use_ok('Business::EDI');
    use_ok('Business::EDI::CodeList');
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
$Business::EDI::Spec::debug =
$Data::Dumper::Indent = $debug;

my ($ob1, $edi);
ok($edi = Business::EDI->new(),                            "Business::EDI->new");
ok(! defined($edi->spec()),                                "Business::EDI->new->spec() starts undef");
ok($edi->spec('default'),                                  "Business::EDI->new->spec('default')");
ok(  defined($edi->spec()),                                "edi->spec() defined after previous constructor call to ->spec(...)");
ok($edi->spec->version,                                    'edi->spec->version')
    and note "default version: " . $edi->spec->version;

ok($edi = Business::EDI->new(version => 'd08a'),           "Business::EDI->new(version => 'd08a')");
is_deeply($edi->spec, Business::EDI->spec('d08a'),         "Business::EDI->spec('d08a') -- 1 arg class method constructor");
is($edi->spec->version, 'd08a', 'edi->spec->version');
is($edi->spec->interactive,  0, 'edi->spec->interactive');


my @methods = ('new', 'spec', 'codelist', 'segment');
foreach (@methods) {
    can_ok($edi, $_);   # must be real methods, not AUTOLOADed
}
my $spec1 = $edi->spec('d07a');
ok($spec1,  'edi->spec("d07a")');
is($spec1->version, 'd07a', 'edi->version');
is_deeply($spec1, Business::EDI->spec('d07a'),            "Business::EDI->spec('d07a') matches edi->spec('d07a') -- 1 arg object method constructor");
is_deeply($spec1, Business::EDI->spec(version => 'd07a'), "Business::EDI->spec('d07a') matches edi->spec(version => 'd07a') -- 1 arg object method constructor");

ok($ob1 = Business::EDI->codelist('ResponseTypeCode', $data->{4343}),
    sprintf("Business::EDI->codelist('ResponseTypeCode', \$X): 4343 Response Type Code '%s' recognized", ($data->{4343} || ''))
);
is_deeply($ob1, Business::EDI->codelist(4343, $data->{4343}), "ResponseTypeCode and 4343 create identical objects");

my $pre = "Identical constructors: Business::EDI->codelist and";
is_deeply($ob1, Business::EDI::CodeList->new_codelist(4343,    $data->{4343}), "$pre Business::EDI::CodeList->new_codelist");
is_deeply($ob1, Business::EDI::CodeList::ResponseTypeCode->new($data->{4343}), "$pre Business::EDI::CodeList::ResponseTypeCode->new");

my ($spec2);
foreach my $type (qw/message segment composite element/) {
    ok(  $edi->spec->get_spec_handle($type), "spec->get_spec_handle('$type')");
    ok($spec1 = $edi->spec->get_spec($type), "spec->get_spec('$type')");
    ok($spec2 = $edi->spec->get_spec($type), "spec->get_spec('$type')");
    is_deeply($spec1, $spec2, "cached '$type' spec matches first read");
    # print "$type: ", Dumper($spec1);
}

$debug and print Dumper($spec1->{9619});
