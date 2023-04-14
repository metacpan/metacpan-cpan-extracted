use strict;
use Test::More;

use Catmandu::Importer::PICA;
use Catmandu::Fix;
use PICA::Data 'pica_string';

my $fixer = Catmandu::Fix->new( fixes => [q|
set_field(foo,"FOO")
do pica_diff()
    pica_set(foo,021A$a)
    pica_add(foo,010@$x)
end
|]);
my $importer = Catmandu::Importer::PICA->new( file => "./t/files/minimal.pp", type => "Plain" );
my $record = $fixer->fix( $importer->first );
is pica_string($record->{record}), <<'PICA', "pica_diff";
  003@ $0123
+ 010@ $xFOO
+ 021A $aFOO$xyz
- 021A $abc$xyz

PICA

done_testing;
