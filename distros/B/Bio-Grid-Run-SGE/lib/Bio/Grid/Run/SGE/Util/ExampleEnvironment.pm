package Bio::Grid::Run::SGE::Util::ExampleEnvironment;

use warnings;
use strict;
use Carp;
use File::Spec;
use Cwd;
use Bio::Gonzales::Util::Cerial;
use Sys::Hostname;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.066'; # VERSION

@EXPORT      = qw(get_array_env get_single_env);
%EXPORT_TAGS = ();
@EXPORT_OK   = qw();

my $cwd            = fastgetcwd();
my $system_tmp_dir = File::Spec->tmpdir;

# params:
# job_name
# job_id
# shell
# stderr_dir
# stdout_dir

sub get_single_env {
  my ($p) = @_;

  my %params = (
    job_name   => 'test_job',
    shell      => $ENV{SHELL},
    job_id     => 12345,
    stderr_dir => '.',
    stdout_dir => '.',
    %$p,
  );
  say STDERR jfreeze( \%params ) if ( $p->{verbose} );

  return {
    %ENV,
    HOME     => $ENV{HOME},
    HOSTNAME => ( $ENV{HOSTNAME} // hostname() // 'localhost' ),
    USER     => $ENV{USER},
    LOGNAME  => $ENV{USER},
    #PATH            => "/usr/local/bin:/bin:/usr/bin",
    SHELL       => $params{shell},
    QUEUE       => "all.q",
    REQUEST     => $params{job_name},
    REQNAME     => $params{job_name},
    JOB_NAME    => $params{job_name},
    JOB_ID      => $params{job_id},
    TMP         => $system_tmp_dir,
    TMPDIR      => $system_tmp_dir,
    TERM        => "linux",
    ENVIRONMENT => "BATCH",

    SGE_TASK_ID    => "undefined",
    SGE_TASK_FIRST => "undefined",
    SGE_TASK_LAST  => "undefined",

    SGE_O_HOST    => "cluster",
    SGE_O_HOME    => $ENV{USER},
    SGE_O_LOGNAME => $ENV{USER},
    SGE_O_PATH    => $ENV{PATH},
    SGE_O_MAIL    => "/var/spool/mail/$ENV{USER}",
    SGE_O_WORKDIR => $cwd,
    SGE_O_SHELL   => $ENV{SHELL},

    SGE_STDIN_PATH   => File::Spec->devnull(),
    SGE_STDERR_PATH  => "$params{stderr_dir}/$params{job_name}.e$params{job_id}",
    SGE_STDOUT_PATH  => "$params{stdout_dir}/$params{job_name}.o$params{job_id}",
    SGE_CLUSTER_NAME => "cluster",
    SGE_CWD_PATH     => $cwd,
  };
}

# params:
# job_name
# job_id
# shell
# stderr_dir
# stdout_dir
# range = [ from, this_task_id, to]

sub get_array_env {
  my ($p) = @_;

  my $env = get_single_env(@_);
  say STDERR jfreeze($p) if ( $p->{verbose} );
  return {
    %$env,
    "SGE_TASK_FIRST" => ( $p->{range}[0] // 1 ),    #first task id
    "SGE_TASK_LAST"  => ( $p->{range}[2] // 11 ),
    "SGE_TASK_STEPSIZE" => 1,
    "SGE_TASK_ID"       => ( $p->{range}[1] // 3 ),                                   #1-based
    SGE_STDERR_PATH     => $env->{SGE_STDERR_PATH} . "." . ( $p->{range}[1] // 3 ),
    SGE_STDOUT_PATH     => $env->{SGE_STDERR_PATH} . "." . ( $p->{range}[1] // 3 ),
  };
}

1;
