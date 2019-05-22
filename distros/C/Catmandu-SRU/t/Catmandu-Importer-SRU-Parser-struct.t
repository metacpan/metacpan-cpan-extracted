use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::SRU;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::SRU::Parser::struct';
    use_ok $pkg;
}

require_ok $pkg;

done_testing;
