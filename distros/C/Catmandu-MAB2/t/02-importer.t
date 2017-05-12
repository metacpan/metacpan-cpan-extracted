use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Importer::MAB2;

my $importer = Catmandu::Importer::MAB2->new(file => "./t/mab2.dat", type=> "RAW");
my @records;
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 20, 'records');
ok( $records[0]->{'_id'} eq '47918-4', 'record _id' );
is_deeply( $records[0]->{'record'}->[0], ['LDR', '', '_', '02020nM2.01200024      h'],
    'record leader'
);

$importer = Catmandu::Importer::MAB2->new(file => "./t/mab2.xml", type=> "XML");
@records = ();
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 20, 'records');
ok( $records[0]->{'_id'} eq '47918-4', 'record _id' );
is_deeply( $records[0]->{'record'}->[0], ['001', ' ', '_', '47918-4'],
    'record field'
);


$importer = Catmandu::Importer::MAB2->new(file => "./t/mab2disk.dat", type=> "Disk");
@records = ();
$importer->each(
    sub {
        push( @records, $_[0] );
    }
);
ok(scalar @records == 20, 'records');
ok( $records[0]->{'_id'} eq '47918-4', 'record _id' );
is_deeply( $records[0]->{'record'}->[0], ['LDR', '', '_', '02020nM2.01200024      h'],
    'record field'
);

done_testing;