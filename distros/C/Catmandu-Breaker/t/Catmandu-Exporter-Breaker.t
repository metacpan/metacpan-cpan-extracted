#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

BEGIN {
    use_ok 'Catmandu::Exporter::Breaker';
}

require_ok 'Catmandu::Exporter::Breaker';

{
	my $file = "";
	my $importer = Catmandu->importer('JSON',file => 't/oai_dc.json');
	my $exporter = Catmandu::Exporter::Breaker->new(file => \$file);

	$exporter->add_many($importer);

	$exporter->commit;

	is $exporter->count , 20 , 'Breaking OAI-DC ok';
}

{
	my $file = "";
	my $importer = Catmandu->importer('JSON',file => 't/marcxml.json');
	my $exporter = Catmandu::Exporter::Breaker->new(file => \$file, handler => 'marc');

	$exporter->add_many($importer);

	$exporter->commit;

	is $exporter->count , 20 , 'Breaking MARCXML ok';
}

{
	my $file = "";
	my $importer = Catmandu->importer('JSON',file => 't/pica.json');
	my $exporter = Catmandu::Exporter::Breaker->new(file => \$file, handler => 'pica');

	$exporter->add_many($importer);

	$exporter->commit;

	is $exporter->count , 5 , 'Breaking PICA ok';

    like $file, qr/^658700774\t001\@0\t703/, 'PICA breaker format ok';
}

done_testing;
