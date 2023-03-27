use strict;
use Test::More;

use Catmandu;
use Catmandu::Fix;
use Catmandu::Importer::PICA;
use PICA::Data 'pica_string';

sub test_fix {
    my ($fix, $expect) = @_;
    my $fixer = Catmandu::Fix->new( fixes => [$fix] );
    my $importer = Catmandu::Importer::PICA->new( file => "./t/files/minimal.pp", type => "Plain" );
    my $record = $fixer->fix( $importer->first );
    my $result = pica_string($record);
    $result =~ s/\n$//m;
    is $result, $expect, $fix;
}

test_fix('pica_remove(003@)', "021A \$abc\$xyz\n");
test_fix('pica_remove(003@$0)', "021A \$abc\$xyz\n");
test_fix('pica_remove(021A$x)', "003@ \$0123\n021A \$abc\n");
test_fix('pica_remove(021A$xa)', "003@ \$0123\n");

test_fix('pica_keep(003@)', "003@ \$0123\n");
test_fix('pica_keep("003@|021A")', "003@ \$0123\n021A \$abc\$xyz\n");

test_fix('pica_tag("012X")', "012X \$0123\n012X \$abc\$xyz\n");
test_fix('pica_occurrence(1)', "003@/01 \$0123\n021A/01 \$abc\$xyz\n");
test_fix('pica_occurrence(71)', "003@/71 \$0123\n021A/71 \$abc\$xyz\n");

done_testing;
