use warnings;
use Test::More;
use Data::Dumper;
use File::Temp qw/tempdir/;
use Bio::Grid::Run::SGE::Util qw/poll_interval/;
use Bio::Gonzales::Util::Cerial;

use File::Spec;
use List::Util;
use Cwd qw/fastcwd/;
use lib 't/lib';
use Test::Util qw/rewrite_shebang/;
use File::Path qw/remove_tree/;
use Path::Tiny;

$ENV{BGRS_RC_FILE} = '';
BEGIN { use_ok('Bio::Grid::Run::SGE'); }

my $cl_env = File::Spec->rel2abs("scripts/cl_syntax_error.pl");

my $usage = `$^X $cl_env --help`;

diag $usage;

my @elements = ( 'a', 'b', 'c', 'd', 'e', 'f' );
my $tmp_dir = File::Spec->rel2abs('tmp_test');
mkdir $tmp_dir unless ( -d $tmp_dir );

my $job_dir = tempdir( CLEANUP => 1, DIR => $tmp_dir );

my $job_name   = 'test_all_fail';
my $result_dir = 'r';
my $qsub_cmd   = rewrite_shebang( 'bin/qfake.pl', "$job_dir/qfake.pl" );

# create basic config
my $basic_config = {
  input      => [ { format => 'List', elements => \@elements } ],
  job_name   => $job_name,
  mode       => 'Consecutive',
  no_prompt  => 1,
  result_dir => $result_dir,
  submit_bin => $qsub_cmd,
};

yspew( "$job_dir/conf.yml", $basic_config );

system("$^X $cl_env $job_dir/conf.yml");

diag "THIS TEST MIGHT TAKE UP TO 30 MINUTES";
my $max_time = 30 * 60;
my $wait_time = poll_interval( 1, $max_time );
my $finished_successfully;
while ( $wait_time < $max_time ) {

  diag "  next poll in $wait_time seconds";
  sleep $wait_time;

  if ( -f "$job_dir/$result_dir/finished" ) {
    open my $fh, '<', "$job_dir/$result_dir/finished" or die "Can't open filehandle: $!";
    $finished_successfully = <$fh>;
    $fh->close;
    chomp $finished_successfully;
    last;
  }
  $wait_time = poll_interval( $wait_time, $max_time );
}
ok($finished_successfully);

my @files
  = path($job_dir)->child($result_dir)->children(qr/^$job_name.*$finished_successfully.*\.env\.json$/);

my $env = jslurp( $files[-2] );

is( $env->{JOB_NAME}, $job_name );

my %found_elements;
my @item_files
  = path($job_dir)->child($result_dir)->children(qr/^$job_name.*$finished_successfully.*\.item\.json$/);
for my $f (@item_files) {
  my $items = jslurp($f);
  for my $item (@$items) {
    $found_elements{$item}++;
  }
}
is_deeply( [ sort keys %found_elements ], [ sort @elements ] );

remove_tree($tmp_dir);
done_testing();
