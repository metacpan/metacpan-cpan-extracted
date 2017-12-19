#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;
use Catmandu::Importer::MARC;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::ISO';
    use_ok $pkg;
}

require_ok $pkg;

my $marciso = undef;

my $record = {
    _id => '000000002',
    record => [
      [ 'LDR', ' ', ' ' , '_', '00209nam a2200097 i 4500' ] ,
      [ '001', ' ', ' ' , '_', '000000002' ] ,
      [ '008', ' ', ' ' , '_', '050601s1921    xx |||||||||||||| ||dut  ' ],
      [ '245', '1', '0' , 'a', 'Catmandu Test' ] ,
      [ '650', ' ', '0' , 'a', 'Perl' ] ,
      [ '650', ' ', '0' , 'a', 'MARC' , 'a' , 'MARC2' ] ,
      [ '650', ' ', '0' , 'a', '加德滿都' ] ,
    ]
};

note("export marc");
{
    my $exporter = Catmandu::Exporter::MARC->new(file => \$marciso, type=> 'ISO');

    ok $exporter , 'got a MARC/ISO exporter';

    ok $exporter->add($record) , 'add';

    ok $exporter->commit , 'commit';

    ok length($marciso) >= 127 , 'got iso';
}

note("parse the results");
{
    my $importer = Catmandu::Importer::MARC->new(file => \$marciso , type => 'ISO');

    ok $importer , 'got a MARC/ISO importer';

    my $result = $importer->first;

    ok $result , 'got a result';

    is_deeply $result , $record , 'got the expected result';
}

done_testing;
