use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Importer::PICA;

note 'XML';
my $importer = Catmandu::Importer::PICA->new(file => "./t/files/picaxml.xml", type=> "XML");
my @records;
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 5, 'records');
ok( $records[0]->{'_id'} eq '658700774', 'record _id' );
is_deeply( $records[0]->{'record'}->[7], ['003@', '', '0', '658700774'],
    'record field'
);

note 'Plus';
$importer = Catmandu::Importer::PICA->new(file => "./t/files/picaplus.dat", type=> "PICAplus");
@records = ();
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 10, 'records');
ok( $records[0]->{'_id'} eq '1041318383', 'record _id' );
is_deeply( $records[0]->{'record'}->[5], ['003@', '', '0', '1041318383'],,
    'record field'
);

note 'PPXML';
$importer = Catmandu::Importer::PICA->new(file => "./t/files/ppxml.xml", type=> "PPXML");
@records = ();
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 2, 'records');
ok( $records[0]->{'_id'} eq '1027146724', 'record _id' );
is_deeply( $records[0]->{'record'}->[7], ['003@', '', '0', '1027146724'],
    'record field'
);
ok(Catmandu::Importer::PICA->new(file => "./t/files/ppxml.xml", type=> "PicaPlusXML"), 'PicaPlusXML');

done_testing;
