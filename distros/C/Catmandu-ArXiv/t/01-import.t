use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::ArXiv';
    use_ok $pkg;
}

require_ok $pkg;

dies_ok { $pkg->new() } "missing arguments";

is $pkg->new( id => '1408.6349' )->count, 1, "count ok";

is $pkg->new( id => '1408.6349,1408.6320,1408.6105' )->count, 3, "count ok";

is $pkg->new( query => "electron", limit => 20 )->count, 20, "count ok";

lives_ok { $pkg->new(query => '0000-0002-6477-8992') } "pass orcid argument";

ok $pkg->new(query => '0000-0002-6477-8992')->count >= 1, "at least one record";

done_testing;
