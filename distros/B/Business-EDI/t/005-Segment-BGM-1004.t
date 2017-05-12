#!/usr/bin/perl
#

use strict; use warnings;

use Test::More tests => 18;

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

use vars qw/$bgm $edi/;

$verbose and note "data: " . Dumper($data);

ok($edi = Business::EDI->new('d08a'),  'Business::EDI->new("d08a")');
ok($edi->spec,                         'edi->spec()');
ok($bgm = $edi->segment('BGM', $data), 'edi->segment("BGM", ...)');
$verbose and print Dumper ($bgm);
ok($bgm->spec,                         'bgm->spec()');
ok($bgm->part(1004),                   "bgm->part(1004)");

foreach my $key (keys %$data) {
    ok($bgm->part($key), "bgm->part('$key')");
}

foreach my $key (1004) {
    my ($msgtype);
    ok($msgtype = $edi->subelement({$key => $data->{$key}}),
                  "edi->subelement({$key => $data->{$key}}): Code $key recognized"
    );
    note "\nref(subelement): " . ref($msgtype);
    $verbose and print "subelement: ", Dumper($msgtype);
    is_deeply($msgtype, $bgm->part($key),        "Different constructor paths, identical object ($key)");
    is($msgtype->code,  $bgm->part($key)->code , "Different constructor paths, same code ($key)");
    is($msgtype->label, $bgm->part($key)->label, "Different constructor paths, same label ($key)");
    is($msgtype->value, $bgm->part($key)->value, "Different constructor paths, same value ($key)");
    $verbose and note(ref($msgtype)  . ' dump: ' . Dumper($msgtype));
}

note("done");

