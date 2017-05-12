#!/usr/bin/perl
#

use strict; use warnings;

use Test::More tests => 33;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('Business::EDI');
    use_ok('Business::EDI::DataElement');
    # use_ok('Business::EDI::Segment::RFF');
    use_ok('Business::EDI::Segment::BGM');
}

my $verbose = @ARGV ? shift : 0;
$Business::EDI::debug = $verbose;
$Business::EDI::Segment::BGM::debug = $verbose;
$Business::EDI::CodeList::verbose   = $verbose;

my $data = {
    '1004' => '582830',
    '4343' => 'AC',
    '1225' => '29',
    'C002' => {
        '1001' => '231'
    }
};

$Data::Dumper::Indent = 1;

use vars qw/%code_hash $bgm $codemap $edi/;

note "data: " . Dumper($data);

ok($edi = Business::EDI->new('d08a'),  'Business::EDI->new("d08a")');
ok($bgm = $edi->segment('BGM', $data), 'edi->segment("BGM", ...)');
$verbose and print "BGM: ",          Dumper($bgm);
$verbose and print "BGM->seg4343: ", Dumper($bgm->seg4343);
ok($bgm->seg4343, "seg4343 Autoload accessor");
my $seg4343 = $bgm->seg4343;
isa_ok($seg4343, "Business::EDI::CodeList::ResponseTypeCode", "BGM->seg4343");
is_deeply($seg4343, $bgm->part(4343), "part(4343) accessor");
is_deeply($seg4343, $bgm->part4343,   "part4343 Autoload accessor");
$verbose and note("BGM->seg4343->value: " . $bgm->seg4343->value);
is($bgm->seg4343->value, $data->{4343}, "seg4343 value");

ok($codemap = $bgm->seg4343->codemap, "Business::EDI::Segment::BGM->new(...)->seg4343->codemap");

foreach my $key (keys %$data) {
    my ($msgtype);
    ok($msgtype = $edi->subelement({$key => $data->{$key}}),
                  "edi->subelement({$key => $data->{$key}}): Code $key recognized"
    );
    note "ref(subelement): " . ref($msgtype);
    if ($key eq 'C002') {
        ok($msgtype->part(1001), "Extra test for direct access to element (1001) grouped under C002");
    }
    is_deeply($msgtype, $bgm->part($key),        "Different constructor paths, identical object ($key)");
    is($msgtype->code,  $bgm->part($key)->code , "Different constructor paths, same code ($key)");
    is($msgtype->label, $bgm->part($key)->label, "Different constructor paths, same label ($key)");
    is($msgtype->value, $bgm->part($key)->value, "Different constructor paths, same value ($key)");
    $verbose and note(ref($msgtype)  . ' dump: ' . Dumper($msgtype));
}

note("done");

