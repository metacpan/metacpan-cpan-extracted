use strict;
use warnings;

use Catmandu::Importer::JSON;
use Catmandu::Importer::MARC;

use Test::More tests => 11;

my $fixer = Catmandu::Fix->new(fixes => ['marc_map("245a","title"); marc_map("500a","test")']);
my $importer = Catmandu::Importer::JSON->new( file => 't/old_new.json' );
my $records = $fixer->fix($importer)->to_array;

ok(@$records == 2 , "Found 2 records");
ok(defined($records->[0]->{title}), "0 has title");
ok(defined($records->[1]->{title}), "1 has title");
is($records->[0]->{title},'ActivePerl with ASP and ADO /',"0 has correct title");
is($records->[1]->{title},'ActivePerl with ASP and ADO /',"1 has correct title");

$importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );
$records = $fixer->fix($importer)->to_array;

ok(defined($records->[0]->{title}), "1 has title");
is($records->[0]->{title},'ActivePerl with ASP and ADO /',"0 has correct title");
ok(&f245_contains_no_underscore($records->[0]),"MARC importer using the new syntax");

$importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph' , type => "ALEPHSEQ");
$records = $fixer->fix($importer)->to_array;

ok(defined($records->[0]->{title}), "1 has title");
is($records->[0]->{title},'Propositional structure and illocutionary force :',"0 has correct title");
ok(&f245_contains_no_underscore($records->[0]),"MARC importer using the new syntax");

sub f245_contains_no_underscore {
	my $record = shift;
	for (@{$record->{record}}) {
		return 0 if ($_->[0] eq '245' && $_->[3] eq '_');
	}
	return 1;
}