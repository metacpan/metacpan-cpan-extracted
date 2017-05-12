use strict;
use Test::More;

foreach ( <DATA> ) {
    chomp;
    use_ok $_;
}

diag "Testing Catmandu::PICA $Catmandu::PICA::VERSION, Perl $], $^X";

done_testing;

# find lib -iname *.pm | perl -pe 's/\//::/g;s/^lib::|.pm$//g'
__DATA__
Catmandu::Importer::PICA
Catmandu::Exporter::PICA
Catmandu::PICA
Catmandu::Fix::pica_map
