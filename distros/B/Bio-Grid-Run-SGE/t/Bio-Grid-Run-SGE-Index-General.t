use warnings;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempdir/;
use File::Compare qw/compare/;
use File::Spec::Functions qw/catfile/;
use Bio::Gonzales::Seq::IO qw/faslurp/;
use Carp;

BEGIN { 
  $Bio::Gonzales::Seq::WIDTH = 60;
  use_ok('Bio::Grid::Run::SGE::Index::General');
}


my $td = tempdir( CLEANUP => 1 );

my $idx = Bio::Grid::Run::SGE::Index::General->new(
    'writeable' => 1,
    'idx_file'  => catfile( $td, 'test.idx' ),
    'sep'       => '^>'
);
#use two files, one big index
$idx->create( [ 't/data/test.fa', 't/data/test.fa' ] );

{
    my $same_idx = Bio::Grid::Run::SGE::Index::General->new(
        'idx_file' => catfile( $td, 'test.idx' ),
        'sep'      => '^>'
    );
    ok( $same_idx->_is_indexed );

    my $changed_idx = Bio::Grid::Run::SGE::Index::General->new(
        'idx_file' => catfile( $td, 'test.idx' ),
        'sep'      => '^;'
    );
    ok( !$changed_idx->_is_indexed );
}

my $range_tmp = catfile( $td, 'range.fa' );
my @ids;

@ids = ( 44, 0 );
open my $r1_fh, '>', $range_tmp or die "Can't open filehandle: $!";
for my $id (@ids) {
    my $data = $idx->get_elem($id);
    print $r1_fh $data;
}
$r1_fh->close;

is( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-44-44-0.ref.fa' ), 0, 'range 44,44,0' );

unlink $range_tmp if ( -f $range_tmp );
@ids = ( 1, 2 );
open my $range_fh, '>', $range_tmp or confess "Can't open filehandle: $!";
for my $id (@ids) {
    my $data = $idx->get_elem($id);
    print $range_fh $data;
}
$range_fh->close;

isnt( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-44-44-0.ref.fa' ),
    0, 'range 44,44,0' );
is( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-1-2.ref.fa' ), 0, 'range 1,2' );

unlink $range_tmp if ( -f $range_tmp );
@ids = ( 44, 1 );

open my $r2_fh, '>', $range_tmp or die "Can't open filehandle: $!";
for my $id (@ids) {
    my $data = $idx->get_elem($id);
    print $r2_fh $data;
}
$r2_fh->close;

isnt( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-44-44-0.ref.fa' ),
    0, 'range 44,44,0' );
isnt( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-1-2.ref.fa' ), 0, 'range 1,2' );
is( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-44-44-1.ref.fa' ), 0, 'range 44,44,1' );

@ids = ( 45, 46, 47, 2 );
unlink $range_tmp if ( -f $range_tmp );
open my $r3_fh, '>', $range_tmp or die "Can't open filehandle: $!";
for my $id (@ids) {
    my $data = $idx->get_elem($id);
    print $r3_fh $data;
}
$r3_fh->close;

is( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-45-47-2.ref.fa' ), 0, 'range 45,47,2' );

is( $idx->num_elem, 90, "number of elements" );

{
    my $idx_nosep = Bio::Grid::Run::SGE::Index::General->new(
        'writeable'      => 1,
        'idx_file'       => catfile( $td, 'test_no-sep.skip-first.idx' ),
        'sep'            => '^>',
        'sep_remove'     => 1,
        'ignore_first_sep' => 1,
    );

    $idx_nosep->create( [ 't/data/test.fa', 't/data/test.fa' ] );

    my @ids_nosep = ( 45, 46, 47, 2 );
    my $rtmp_nosep = catfile( $td, '45-47-2_no-sep.skip-first.dat' );
    open my $r_nosep_fh, '>', $rtmp_nosep or die "Can't open filehandle: $!";
    for my $id (@ids_nosep) {
        my $data = $idx_nosep->get_elem($id);
        print $r_nosep_fh $data;
    }
    $r_nosep_fh->close;

    #system("diff -u $rtmp_nosep t/data/Bio-Grid-Run-SGE-Index-General.range-45-47-2.nosep.ref.fa >&2");
    is(
        compare( $rtmp_nosep, 't/data/Bio-Grid-Run-SGE-Index-General.range-45-47-2.nosep.skipfirst.ref.fa' ),
        0,
        'nosep, range 45,47,2'
    );
}
{
    my $idx_nosep = Bio::Grid::Run::SGE::Index::General->new(
        'writeable'  => 1,
        'idx_file'   => catfile( $td, 'test_no-sep.idx' ),
        'sep'        => '^>.*',
        'sep_remove' => 1,
    );

    $idx_nosep->create( [ 't/data/test.fa', 't/data/test.fa' ] );

    my @ids_nosep = ( 45, 46, 47, 2 );
    my $rtmp_nosep = catfile( $td, '45-47-2_no-sep.dat' );
    open my $r_nosep_fh, '>', $rtmp_nosep or die "Can't open filehandle: $!";
    for my $id (@ids_nosep) {
        my $data = $idx_nosep->get_elem($id);
        print $r_nosep_fh $data;
    }
    $r_nosep_fh->close;

    system("diff -u $rtmp_nosep t/data/Bio-Grid-Run-SGE-Index-General.range-45-47-2.nosep.ref.fa >&2");
    is( compare( $rtmp_nosep, 't/data/Bio-Grid-Run-SGE-Index-General.range-45-47-2.nosep.ref.fa' ),
        0, 'nosep, range 45,47,2' );
}

{
    my $idx_nosep = Bio::Grid::Run::SGE::Index::General->new(
        'writeable'  => 1,
        'idx_file'   => catfile( $td, 'test_no-sep_end.idx' ),
        'sep'        => '^>',
        'sep_remove' => 1,
        'sep_pos'    => '$',
    );
    $idx_nosep->create( [ 't/data/test.fa', 't/data/test.fa' ] );

    my @ids_nosep = ( 45, 46, 47, 2 );
    my $rtmp_nosep = catfile( $td, '45-47-2_no-sep_end.dat' );
    open my $r_nosep_fh, '>', $rtmp_nosep or die "Can't open filehandle: $!";
    for my $id (@ids_nosep) {
        my $data = $idx_nosep->get_elem($id);
        print $r_nosep_fh $data;
    }
    $r_nosep_fh->close;

    is( compare( $rtmp_nosep, 't/data/Bio-Grid-Run-SGE-Index-General.range-45-47-2.nosep.ref.fa' ),
        0, 'nosep end, range 45,47,2' );
}

{
    my $idx_file_empty = catfile( $td, 'test_empty0.idx' );
    my $empty_tmp      = catfile( $td, "empty0.fa" );
    open my $empty_tmp_fh, '>', $empty_tmp or confess "Can't open filehandle: $!";
    $empty_tmp_fh->close;
    my $idx_empty = Bio::Grid::Run::SGE::Index::General->new(
        'writeable'  => 1,
        'idx_file'   => $idx_file_empty,
        'sep'        => '^>',
        'chunk_size' => 5,
    );
    $idx_empty->create( [$empty_tmp] );

    is( $idx_empty->get_elem(0), undef, "empty idx" );
}

{
    my $idx_file_empty = catfile( $td, 'test_empty1.idx' );
    my $empty_tmp      = catfile( $td, "empty1.fa" );
    open my $empty_tmp_fh, '>', $empty_tmp or confess "Can't open filehandle: $!";
    $empty_tmp_fh->close;
    my $idx_empty = Bio::Grid::Run::SGE::Index::General->new(
        'writeable'  => 1,
        'idx_file'   => $idx_file_empty,
        'sep'        => '^>',
        'chunk_size' => 1,
    );
    $idx_empty->create( [ $empty_tmp, 't/data/test.fa' ] );

    is( $idx_empty->get_elem(0), faslurp('t/data/test.fa')->[0]->all_pretty, "empty1 idx" );
}

# CHUNKY
my $idx_file = catfile( $td, 'test2.idx' );
my $idx2 = Bio::Grid::Run::SGE::Index::General->new(
    'writeable'  => 1,
    'idx_file'   => $idx_file,
    'sep'        => '^>',
    'chunk_size' => 5,
);
#use two files, one big index
$idx2->create( [ 't/data/test.fa', 't/data/test.fa' ] );

#check for reindex caching
my $idx_file_age = ( stat $idx_file )[9];
$idx2->create( [ 't/data/test.fa', 't/data/test.fa' ] );
is( ( stat $idx_file )[9], $idx_file_age, 'no reindex necessary' );

#diag Dumper $idx2;

$range_tmp = catfile( $td, 'range_chunky.fa' );

@ids = ( 0 .. 2 );
open my $range_chunky_fh, '>', $range_tmp or die "Can't open filehandle: $!";
for my $id (@ids) {
    my $data = $idx2->get_elem($id);
    print $range_chunky_fh $data;
}
$range_chunky_fh->close;

is( compare( $range_tmp, 't/data/Bio-Grid-Run-SGE-Index-General.range-chunky-0-2.ref.fa' ),
    0, 'range chunky 0 .. 2' );

done_testing();
