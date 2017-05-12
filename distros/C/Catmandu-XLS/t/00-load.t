use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::XLS';
    use_ok $pkg;
    $pkg = 'Catmandu::Exporter::XLSX';
    use_ok $pkg;
    $pkg = 'Catmandu::Importer::XLS';
    use_ok $pkg;
    $pkg = 'Catmandu::Importer::XLSX';
    use_ok $pkg;
}
require_ok $pkg;

done_testing;