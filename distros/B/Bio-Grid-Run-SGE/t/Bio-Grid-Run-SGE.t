use warnings;
use Test::More;
use Data::Dumper;
use Carp;

BEGIN {
  use_ok('Bio::Grid::Run::SGE');

  use_ok("Bio::Grid::Run::SGE::Log::Analysis");
}

my $d;
sub TEST { $d = $_[0]; }
#TESTS

TEST 'worker is successful';
{

  my $dir       = 'tmp';
  my $test_file = $dir . '/testjob.l234.1';
  mkdir $dir;
  open my $fh, '>', $test_file or confess "Can't open filehandle: $!";

  print $fh <<'EOF';
init: Sat Sep 22 21:14:43 2012
config: /home/bargs001/jobs/2012-09-19_b2g_rice/tmp/b2g_rice.config.dat
id: 220
job_id: 1715200
job_cmd: qsub -t 1-1659 -S /home/bargs001/perl5/perlbrew/perls/perl-5.14.2/bin/perl -N b2g_rice -e /home/bargs001/jobs/
name: compute-1-6.local
err: /home/bargs001/jobs/2012-09-19_b2g_rice/tmp/err/b2g_rice.e1715200.220
out: /home/bargs001/jobs/2012-09-19_b2g_rice/tmp/out/b2g_rice.o1715200.220
sge_id:  220
range: (219,219)
index_file: /home/bargs001/jobs/2012-09-19_b2g_rice/idx/b2g_rice.0.idx
cwd: /home/bargs001/jobs/2012-09-19_b2g_rice
cmd: /home/bargs001/jobs/2012-09-19_b2g_rice/cl_blast-existing-db.pl
run.begin
comp.begin: Sat Sep 22 21:15:43 2012
comp.task.exit.success:: 219
comp.task.file.delete:: 219 /home/bargs001/jobs/2012-09-19_b2g_rice/tmp/worker.j1715200.220.t219.i0.tmp
comp.task.time:: 219 0d 0h 28m 50s
comp.end: Sat Sep 22 21:44:33 2012
comp.time: 0d 0h 28m 50s (1730)
run.end
EOF
  $fh->close;

  Bio::Grid::Run::SGE::Log::Analysis->new(
    c => {
      cmd         => [qw/a b c d e/],
      perl_bin    => '/test/perl',
      stderr_dir  => $dir,
      stdout_dir  => $dir,
      working_dir => $dir,
      submit_bin  => 'qsub',
      log_dir     => $dir,
      job_id      => 234,
      job_name    => 'testjob',
      tmp_dir     => $dir,
      stderr_dir  => $dir
    },
    config_file => 'aaa'
  );
}

done_testing();
