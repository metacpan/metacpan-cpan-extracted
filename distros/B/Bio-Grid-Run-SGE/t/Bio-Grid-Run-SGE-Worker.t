use warnings;
use strict;
use Data::Dumper;
use Test::More skip_all => 1;
use Storable;
use File::Temp qw/tempdir/;
use Bio::Grid::Run::SGE::Util qw/my_glob my_sys expand_path my_mkdir/;
use File::Compare qw/compare/;
use Bio::Grid::Run::SGE::Master;
use Bio::Gonzales::Seq::IO qw/faslurp faspew/;
use File::Spec::Functions qw/catfile/;
use Carp;

BEGIN { use_ok('Bio::Grid::Run::SGE::Worker'); }

require 5.014_000;

my $seqs = faslurp( expand_path('t/data/test.fa') );

my $td = tempdir( CLEANUP => 1 );

sub test_atomic {
    my ( $job_id, $idx, $tid, $seqs ) = @_;

    my $result_file = catfile( $td, "result/cluster_job.j$job_id.t" . $tid . ".result" );
    my $ref = $result_file . ".ref";

    open my $ref_fh, '>', $ref or confess "Can't open filehandle: $!";
    print $ref_fh lc( $seqs->[$idx]->all_pretty );
    $ref_fh->close;

    #diag `cat $result_file`;
    #diag `cat $ref`;
    #diag `find $td`;

    is( compare( $result_file, $ref ), 0, "job: $job_id, task: $tid" );
}

my $job_id = 1;
$ENV{JOB_ID} = $job_id;

undef $Bio::Grid::Run::SGE::Master::RC_FILE;

my $m1 = Bio::Grid::Run::SGE::Master->new(
    working_dir      => $td,
    submit_bin       => 't/Bio-Grid-Run-SGE-Master.qsub.pl',
    cmd              => ['t/Bio-Grid-Run-SGE-Master.script.pl'],
    perl_bin         => 'perl',
    input            => [ { format => 'General', sep => '^>', files => ['t/data/test.fa'], } ],
    use_stdin        => 1,
    result_on_stdout => 1,
    mode           => 'Consecutive',
);

my $cmd1 = $m1->cache_config( "$td/master_config" . $job_id );

for ( my $tid = 1; $tid <= 45; $tid++ ) {
    $ENV{SGE_TASK_ID} = $tid;
    system("$^X t/Bio-Grid-Run-SGE-Master.script.pl -w $td/master_config$job_id 2>/dev/null");

    test_atomic( $job_id, $tid - 1, $tid - 1, $seqs );

}

$job_id++;
$ENV{JOB_ID} = $job_id;
my $m2 = Bio::Grid::Run::SGE::Master->new(
    working_dir          => $td,
    submit_bin           => 't/Bio-Grid-Run-SGE-Master.qsub.pl',
    cmd                  => ['t/Bio-Grid-Run-SGE-Master.script.pl'],
    perl_bin             => 'perl',
    input                => [ { format => 'General', sep => '^>', files => ['t/data/test.fa'], } ],
    use_stdin            => 1,
    result_on_stdout     => 1,
    mode               => 'Consecutive',
    combinations_per_job => 2,
);

my $cmd2 = $m2->cache_config( "$td/master_config" . $job_id );

for ( my $tid = 1; $tid <= 23; $tid++ ) {
    $ENV{SGE_TASK_ID} = $tid;
    system("$^X t/Bio-Grid-Run-SGE-Master.script.pl -w $td/master_config$job_id 2>/dev/null");
    test_atomic( $job_id, $tid - 1, $tid - 1, $seqs );
    test_atomic( $job_id, 22 + $tid, 22 + $tid, $seqs ) if ( 22 + $tid < 45 );
}

$job_id++;
$ENV{JOB_ID} = $job_id;

my $m3 = Bio::Grid::Run::SGE::Master->new(
    working_dir          => $td,
    submit_bin           => 't/Bio-Grid-Run-SGE-Master.qsub.pl',
    cmd                  => ['t/Bio-Grid-Run-SGE-Master.script.pl'],
    perl_bin             => 'perl',
    input                => [ { format => 'General', sep => '^>', files => ['t/data/test.fa'], } ],
    use_stdin            => 1,
    result_on_stdout     => 1,
    mode               => 'Consecutive',
    combinations_per_job => 3,
);

my $cmd3 = $m3->cache_config("$td/master_config$job_id");

for ( my $tid = 1; $tid <= 15; $tid++ ) {
    $ENV{SGE_TASK_ID} = $tid;
    system("$^X t/Bio-Grid-Run-SGE-Master.script.pl -w $td/master_config$job_id 2>/dev/null");

    test_atomic( $job_id, ( $tid * 3 ) - 3, ( $tid * 3 ) - 3, $seqs );
    test_atomic( $job_id, ( $tid * 3 ) - 2, ( $tid * 3 ) - 2, $seqs );
    test_atomic( $job_id, ( $tid * 3 ) - 1, ( $tid * 3 ) - 1, $seqs );
}

done_testing();
