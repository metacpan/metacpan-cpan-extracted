use warnings;
use v5.11;
use strict;

use IO::Handle ();
use Test2::V0;
use Data::Dumper;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions;
use File::Copy;
use File::Path qw/make_path/;
use JSON::XS qw/encode_json/;;

use Bio::Grid::Run::SGE::Index::NDJSON;

my $td = tempdir( CLEANUP => 1 );

my $idx = Bio::Grid::Run::SGE::Index::NDJSON->new(
    'writeable' => 1,
    'idx_file'  => catfile( $td, 'test.idx' ),
    'chunk_size' => 3,
);

my $d1f = catfile($td, 'data1.ndjson');
my $d2f = catfile($td, 'data2.ndjson');
open my $d1fh,'>', $d1f or die "Can't open filehandle: $!";
for my $i (1..7) {
  say $d1fh encode_json([ $i ]);
}
close $d1fh;
open my $d2fh,'>', $d2f or die "Can't open filehandle: $!";
for my $i (8..17) {
  say $d2fh encode_json([ $i ]);
}
close $d2fh;
#use two files, one big index
$idx->create( [$d1f, $d2f] );

my $data;
$data = $idx->get_elem(0);
is($data->{elements}, [ [1], [2], [3] ]);

$data = $idx->get_elem(1);
is($data->{elements}, [ [4], [5], [6] ]);

$data = $idx->get_elem(2);
is($data->{elements}, [ [7] ]);

$data = $idx->get_elem(3);
is($data->{elements}, [[8], [9], [10] ]);

done_testing();
