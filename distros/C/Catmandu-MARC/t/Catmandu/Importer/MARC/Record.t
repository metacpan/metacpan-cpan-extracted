#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use MARC::File::USMARC;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::Record';
    use_ok $pkg;
}

require_ok $pkg;

my $file = MARC::File::USMARC->in('t/camel.mrc');
my @marc_objects;
while ( my $marc = $file->next() ) {
    push( @marc_objects, $marc );
}
$file->close();
undef $file;

my $importer = Catmandu::Importer::MARC->new(type => 'Record' , records => \@marc_objects );

ok $importer , 'got an MARC/Record importer';

my $records = $importer->to_array();

ok( @$records == 10, 'got all records' );
ok( $records->[0]->{'_id'}             eq 'fol05731351 ', 'got _id' );
ok( $records->[0]->{'record'}->[1][-1] eq 'fol05731351 ', 'got subfield' );
ok( $records->[0]->{'_id'} eq $records->[0]->{'record'}->[1][-1],
    '_id matches record id' );

done_testing;
