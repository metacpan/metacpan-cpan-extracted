use warnings;
use 5.010;
use strict;

use IO::Handle ();
use Test::More;
use Data::Dumper;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions qw/catfile rel2abs/;
use File::Copy;
use File::Path qw/make_path/;

use Bio::Gonzales::Util::Cerial;

use Cwd qw/fastcwd/;
use lib 't/lib';
use Test::Util qw/rewrite_shebang/;
use Bio::Gonzales::Util::Log;

BEGIN { use_ok('Bio::Grid::Run::SGE::Master'); }
our $LOG = Bio::Gonzales::Util::Log->new();

my $td = tempdir( CLEANUP => 1 );
my $qsub_cmd = rewrite_shebang( 't/Bio-Grid-Run-SGE-Master.qsub.pl', "$td/Bio-Grid-Run-SGE-Master.qsub.pl" );

$ENV{SGE_TASK_ID} = 1;
$ENV{JOB_ID}      = -1;

{
  my $m = Bio::Grid::Run::SGE::Master->meta;

  diag jfreeze( [ map { $_->name } $m->get_all_attributes ] );
}

my %conf = (
  working_dir => $td,
  submit_bin  => $qsub_cmd,
  input       => [ { format => 'General', sep => '^>', files => ['t/data/test.fa'], } ],
  mode        => 'Dummy',
  job_name    => 'cluster_job',
  custom_config_setting => 2
);

my %env = (
  script_bin => 't/Bio-Grid-Run-SGE-Master.script.pl',
  script_dir => rel2abs('t/'),
);

my $m = Bio::Grid::Run::SGE::Master->new(
  config => \%conf,
  env    => \%env,
  log    => $LOG,
)->prepare;

$m->build_exec_env();

my $run_output = jslurp("$td/cluster_job.tmp/cluster_job.job.conf.json");

my $run_output_ref = yslurp('t/data/Bio-Grid-Run-SGE-Master_run.yml');


#diag Dumper $run_output;

#get the naming of the temp dir right
@{$run_output_ref->{config}}{qw/working_dir stderr_dir tmp_dir result_dir log_dir/}
  = map { $_ ? catfile( $td, $_ ) : $td }
  ( '', qw(cluster_job.tmp/err cluster_job.tmp cluster_job.result cluster_job.tmp/log) );
$run_output_ref->{config}{input}[0]{idx_file} = catfile( $td, 'idx/cluster_job.0.idx' );
$run_output_ref->{env}{job_cmd}             =~ s!/tmp/lXGH5pgD5r!$td!g;
$run_output_ref->{env}{worker_config_file} =~ s!/tmp/lXGH5pgD5r!$td!g;
$run_output_ref->{env}{worker_env_script} =~ s!/tmp/lXGH5pgD5r!$td!g;
my $curdir = fastcwd;
$run_output_ref->{env}{job_cmd}  =~ s!PERL!$^X!g;
$run_output_ref->{env}{perl_bin} =~ s!PERL!$^X!g;
$run_output_ref->{config}{stdout_dir} = catfile( $td, 'cluster_job.tmp', 'out' );
$run_output_ref->{config}{idx_dir}    = catfile( $td, 'idx' );
$run_output_ref->{env}{script_dir} = rel2abs('t');
$run_output_ref->{config}{submit_bin} =~ s!/tmp/lXGH5pgD5r!$td!g;

#yspew 't/data/Bio-Grid-Run-SGE-Master_run1x.yml', $run_output;
is_deeply( $run_output_ref, $run_output, );
$ENV{BIO_GRID_RUN_SGE_TESTDIR} = $td;

#FIXME check output of the run function call
$m->run;
#cmp_deeply( $run_output, $run_output_reference, $d );
ok( -f catfile( $td, "cluster_job.tmp", "log", "main.cluster_job.j-1.cmd" ) );

my $qsub_argv = yslurp( catfile( $td, 'master.qsub.cmd' ) );

is_deeply(
  $qsub_argv,
  [
    '-t',
    '1-45',
    '-S',
    $^X,
    '-N',
    'cluster_job',
    '-e',
    catfile( $td, 'cluster_job.tmp/err' ),
    '-o',
    catfile( $td, 'cluster_job.tmp/out' ),
    catfile( $td, 'cluster_job.tmp/env.cluster_job.pl' ),
    't/Bio-Grid-Run-SGE-Master.script.pl',
    '--stage', 'worker',
    catfile( $td, 'cluster_job.tmp/cluster_job.job.conf.json' )
  ]
);

done_testing();
