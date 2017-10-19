use strict;
use warnings;
use Test::Exception;
use Test::More;

use Catmandu;
use Catmandu::Importer::MAB2;

note 'Catmandu::Importer::MAB2 RAW';
{
    my $importer = Catmandu::Importer::MAB2->new(
        file => './t/mab2.dat',
        type => 'RAW'
    );
    my @records;
    $importer->each(
        sub {
            push( @records, $_[0] );
        }
    );
    ok( scalar @records == 20,             'records' );
    ok( $records[0]->{'_id'} eq '47918-4', 'record _id' );
    is_deeply(
        $records[0]->{'record'}->[0],
        [ 'LDR', '', '_', '02020nM2.01200024      h' ],
        'record leader'
    );
}

note 'Catmandu::Importer::MAB2 XML';
{
    my $importer = Catmandu::Importer::MAB2->new(
        file => './t/mab2.xml',
        type => 'XML'
    );
    my @records = ();
    $importer->each(
        sub {
            push( @records, $_[0] );
        }
    );
    ok( scalar @records == 20,             'records' );
    ok( $records[0]->{'_id'} eq '47918-4', 'record _id' );
    is_deeply(
        $records[0]->{'record'}->[0],
        [ '001', ' ', '_', '47918-4' ],
        'record field'
    );
}

note 'Catmandu::Importer::MAB2 Disk';
{
    my $importer = Catmandu::Importer::MAB2->new(
        file => './t/mab2disk.dat',
        type => 'Disk'
    );
    my @records = ();
    $importer->each(
        sub {
            push( @records, $_[0] );
        }
    );
    ok( scalar @records == 20,             'records' );
    ok( $records[0]->{'_id'} eq '47918-4', 'record _id' );
    is_deeply(
        $records[0]->{'record'}->[0],
        [ 'LDR', '', '_', '02020nM2.01200024      h' ],
        'record field'
    );
}

note 'Catmandu::Importer::MAB2 Exception';
{
    throws_ok {
        Catmandu::Importer::MAB2->new(
            file => './t/mab2disk.dat',
            type => 'XYZ'
            )->next
    }
    qr/^unknown type/, 'got exeption';
}

done_testing;
