package Bio::Grid::Run::SGE;

use warnings;
use strict;
use 5.010;

use Carp;

use Bio::Grid::Run::SGE::Master;
use Bio::Grid::Run::SGE::Worker;
use Bio::Grid::Run::SGE::Config;
use Bio::Grid::Run::SGE::Util qw/my_glob my_sys INFO delete_by_regex my_sys_non_fatal/;
use Bio::Grid::Run::SGE::Log::Analysis;
use Data::Dumper;

use IO::Prompt::Tiny qw/prompt/;
use File::Spec;
use Storable;
use Getopt::Long::Descriptive;
use Bio::Gonzales::Util::Cerial qw/yslurp/;
use Cwd qw/fastcwd/;
use Scalar::Util qw/blessed/;

use base 'Exporter';

our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.042'; # VERSION

@EXPORT      = qw(run_job INFO my_sys my_sys_non_fatal my_glob);
%EXPORT_TAGS = ();
@EXPORT_OK   = qw();

sub run_job {
  my $a;
  if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
    $a = $_[0];
  } else {
    $a = {@_};
  }

  confess "main task missing" unless ( $a->{task} );

  my ( $opt, $usage ) = describe_options(
    "%c %o [<config_file>] [<arg1> <arg2> ... <argn>]\n"
      . "%c %o --no_config_file [<arg1> <arg2> ... <argn>]",
    [ 'help|h',           'print help message and exit' ],
    [ 'no_config_file|n', "do not expect a config file as first argument" ],
    [ 'worker|w',         "run as worker (invoked by qsub)" ],
    [ 'post_task|p=i',    "run post task with id of previous task" ],
    [ 'range|r=s',        "run predefined range" ],
    [ 'job_id=s',         "run under this job_id" ],
    [ 'id=s',             "run under this worker id" ],
    [ 'no_prompt',        "ask no confirmation stuff for running a job" ],
    [ 'node_log=i',       "rerun the nodelog stuff" ],
  );

  if ( $opt->help ) {
    print "STANDARD USAGE INFO OF Bio::Grid::Run::SGE\n";
    print( $usage->text );
    if ( $a->{usage} ) {
      print "\n\nCLUSTER SCRIPT USAGE INFO\n";
      my $script_usage = ref $a->{usage} eq 'CODE' ? $a->{usage}->() : $a->{usage};
      print $script_usage;
    }
    exit;
  }

  my $config_file;
  # the script might be invoked with the no_config_file option
  $config_file = shift @ARGV
    unless ( $opt->no_config_file );

  #this is either the original yaml config or a serialized config object
  if ( $config_file && -f $config_file ) {
    $config_file = File::Spec->rel2abs($config_file);
    # if no config file supplied, do not change to any directory
    my $dest_dir = ( File::Spec->splitpath($config_file) )[1];
    chdir($dest_dir);
  }
  my @script_args = @ARGV;

  if ( $opt->worker ) {
    # WORKER

    # the worker needs the config file
    die "no config file given" unless ( -f $config_file );

    _run_worker(
      {
        config_file => $config_file,
        a           => $a,
        range       => $opt->range,
        job_id      => $opt->job_id,
        id          => $opt->id
      }
    );

  } elsif ( $opt->node_log ) {
    #NODE LOG

    die "no config file given" unless ( -f $config_file );
    _run_post_task( $config_file, $opt->node_log );

  } elsif ( $opt->post_task ) {
    #POST TASK

    die "no config file given" unless ( -f $config_file );
    _run_post_task( $config_file, $opt->post_task, $a->{post_task} );

  } else {
    #MASTER

    # get the configuration. hide notify stuff, because it contains passwords.
    # it gets reread (with passwords) separately in the log analysis
    my $c = Bio::Grid::Run::SGE::Config->new(
      job_config_file      => $config_file,
      opt                  => $opt,
      cluster_script_args  => \@script_args,
      cluster_script_setup => $a
    )->hide_notify_settings->config;

    _run_master( $c, $a );

  }

  return;
}

sub _run_master {
  my ( $c, $a ) = @_;

  # CHANGE TO THE WORKING DIR

  # we are already in the dir of the config file, if given. (see further up)
  # so relative paths are based on the config file dir
  # if no config file, we are still in the directory from where we started the script
  # policy
  # 1. working dir config entry
  # 2. dir of config file if config file
  # 3. current dir if no config file

  my $working_dir = $c->{working_dir} // fastcwd();

  my $current_dir = fastcwd();
  if ( $working_dir && -d $working_dir ) {
    $c->{working_dir} = File::Spec->rel2abs($working_dir);
    chdir $working_dir;
  }

  #initiate master
  if ( $a->{pre_task} ) {
    confess "pre_task is no code reference"
      if ( ref $a->{pre_task} ne 'CODE' );
  } else {
    INFO("USING DEFAULT MASTER TASK");
    $a->{pre_task} = \&_default_pre_task;
  }


  #get a Bio::Grid::Run::SGE::Master object
  my $m = $a->{pre_task}->($c);

  # if no master object is returned, just take the configuration
  # (it might have changed during the invocation of pre_task)
  $m = _default_pre_task($c)
    unless ( $m && blessed($m) eq 'Bio::Grid::Run::SGE::Master' );

  #confirm
  INFO( $m->to_string );
  if ( $c->{no_prompt} || prompt( "run job? [yn]", 'y' ) eq 'y' ) {
    $m->run;
  }
}

sub _run_worker {
  my $args = shift;
  my %worker_args = ( config_file => $args->{config_file}, task => $args->{a}{task} );
  if ( defined( $args->{range} ) ) {
    my @range = split /[-,]/, $args->{range};

    #one number x: from x to x
    @range = ( @range, @range )
      if ( @range == 1 );

    $worker_args{range} = \@range;
  }

  $worker_args{job_id} = $args->{job_id}
    if ( defined( $args->{job_id} ) );

  $worker_args{id} = $args->{id}
    if ( defined( $args->{id} ) );

  Bio::Grid::Run::SGE::Worker->new( \%worker_args )->run;
}

sub _run_post_task {
  my ( $config_file, $job_id, $post_task ) = @_;

  confess "config file error in worker" unless ( $config_file && -f $config_file );

  #get config
  my $c = retrieve $config_file;
  $c->{job_id} = $job_id;

  # create all summary files and restart scripts
  my $log = Bio::Grid::Run::SGE::Log::Analysis->new( c => $c, config_file => $config_file );
  $log->analyse;
  $log->write;
  $log->notify;

  # run post task, if desired
  $post_task->($c)
    if ( $post_task && !$c->{no_post_task} );

  return;
}

sub _default_pre_task {
  my ($c) = @_;

  return Bio::Grid::Run::SGE::Master->new($c);
}

1;

__END__

=pod

=head1 NAME

Bio::Grid::Run::SGE - Distribute (biological) analyses on the local SGE grid

=head1 SYNOPSIS

Bio::Grid::Run::SGE lets you distribute a computational task on cluster nodes. 

Imagine you want to run a pipeline (a concatenation of several tasks) in
parallel. This is usually no problem, you have plenty of frameworks to do
this. B<However, if ONE task of your pipeline is so big that it is necessary to
split it up into multiple I<subtasks>, then Bio::Grid::Run::SGE may be
extemely useful.>

A simple example would be to calculate the reverse complement of
10,000,000,000,000,000,000 sequences in a FASTA file in a distributed fashion.

To run it with Bio::Grid::Run::SGE, you need

=over 4

=item a. A cluster script that executes the task (or calls a 2nd script that executes the task)

=item b. A job configuration file in YAML format

=item c. Input data

=back

On the commandline this looks like:

    $ perl ./cl_script_with_task.pl job_configuration.conf.yml
    
To continue with the example of the reverse complement (don't worry, the
example does not use 10,000,000,000,000,000,000 sequences, but only the human
CDS sequences):

First, create a perl script F<cl_reverse_complement.pl> that executes the
analysis in the Bio::Grid::Run::SGE environment. 

    #!/usr/bin/env perl

    use warnings;
    use strict;
    use 5.010;

    use Bio::Grid::Run::SGE;
    use Bio::Gonzales::Seq::IO qw/faslurp faspew/;

    run_job(
      task => sub {
        my ( $c, $result_file_name_prefix, $input) = @_;

        # we are using the "General" index, so $input is a filename
        # containing some sequences

        # read in the sequences
        my @sequences = faslurp($input);

        # iterate over them and 
        for my $seq (@sequences) {
          $seq->revcom;
          # calculate the reverse complement
        }
        # finally write the sequences to a results file specific for the current job
        faspew( $result_file_name_prefix . ".fa", @sequences );

        # return 1 for success (0/undef for error)
        return 1;
      }
    );

    1;

Second, download sequences and create a config file F<rc_human.conf.yml> (YAML
format) to specify file names and pipeline parameters.

The example uses human CDS sequences, you have to download them from, e.g. Ensembl:

    $ wget ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/cds/Homo_sapiens.GRCh37.75.cds.all.fa.gz

Currently, Bio::Grid::Run::SGE does not have an index to support on the fly
decompression for input data, so you have to do it on your own:

    $ gunzip Homo_sapiens.GRCh37.75.cds.all.fa.gz

Now you can create the config file F<rc_human.conf.yml> (YAML format) and paste the following text into it:

    ---
    input:
    # use the Bio::Grid::Run::SGE::Index::General index 
    # to index the sequence files
    - format: General
      # supply 100 sequences in one chunk
      # ($input in the cluster script contains 100 sequences)
      chunk_size: 100
      # an array of one or more sequence files
      files: [ 'Homo_sapiens.GRCh37.75.cds.all.fa' ]
      # fasta headers start with '>'
      sep: '^>'
    job_name: reverse_complement

    # iterate consecutively through all sequences 
    # and call cl_reverse_complement.pl on it
    mode: Consecutive

Third, with this basic configuration, you can run the reverse complement
distributed on the cluster by invoking

  perl cl_reverse_complement.pl rc_human.conf.yml

The results will be in F<reverse_complement.result>

There are a lot more options, indices and modes available, see
L</DESCRIPTION> for more info.

=head1 INSTALLATION

=over 4

=item 1. Install L<Bio::Grid::Run::SGE> from CPAN

The tests that are run during installation are expecting qsub and qstat
executables. The tests might fail if you don't have them. Just skip the tests
in this case.

=item 2. Try the stuff in L</SYNOPSIS>

=back

=head1 DESCRIPTION

=head2 Control flow in Bio::Grid::Run::SGE

The general flow starts at running the cluster script. The script defines an
index and an iterator. Indices describe how to split the data into chunks,
whereas iterators describe in what order these chunks get fed to the cluster
script.

Once the script is started, pre tasks might be run and the index is set up. You
have to confirm the setup to start the job on the cluster.
L<Bio::Grid::Run::SGE> is submitting then the cluster script as array job to
the cluster. After the job is finished, post tasks, if specified, are run.

Output is stored in the result folder, intermediate files are stored in the
temporary folder. The temporary folder contains the log, scripts to rerun
failed jobs, update the job status, standard error and output, files
containing data chunks and additional log information.

=head1 DOCUMENTATION CONTENTS

=over 4

=item L<Writing cluster scripts|Bio::Grid::Run::SGE::ClusterScript>

=item L<Writing configuration files|Bio::Grid::Run::SGE::Config>

=item L<Using indices|Bio::Grid::Run::SGE::Index>

=item L<Using iteration modes|Bio::Grid::Run::SGE::Iterator>

=over 4

=item L<Consecutive|Bio::Grid::Run::SGE::Iterator::Consecutive>

=item L<AvsB|Bio::Grid::Run::SGE::Iterator::AvsB>

=item L<AllvsAll|Bio::Grid::Run::SGE::Iterator::AllvsAll>

=item L<AllvsAllNoRep|Bio::Grid::Run::SGE::Iterator::AllvsAllNoRep>

=back

=item L<Job logging|Bio::Grid::Run::SGE::Log>

=item L<Job state notifications|Bio::Grid::Run::SGE::Log::Notify>

=item L<Running other (e.g. Python) scripts|Bio::Grid::Run::SGE::ClusterScript/OTHER>

=back

=head1 INCLUDED 3RD PARTY SOFTWARE

To show running time of jobs,
L<distribution|https://github.com/philovivero/distribution> was used. The
script is distributed under GPL, so honor that if you use this package. I
personally have to thank Tim Ellis for creating such an nice script.

=head1 SEE ALSO

L<Bio::Gonzales>  L<Bio::Grid::Run::SGE::Util>

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
