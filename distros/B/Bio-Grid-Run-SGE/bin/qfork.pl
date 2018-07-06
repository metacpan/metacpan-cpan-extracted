#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;
use List::MoreUtils qw/firstidx/;
use Data::Dumper;
use Carp;
use Bio::Grid::Run::SGE::Util::ExampleEnvironment;
use String::ShellQuote;
use Parallel::ForkManager;
use Getopt::Long;

Getopt::Long::Configure(qw(pass_through no_ignore_case));

my @spec = (
  'a=s',           'ac=s',   'ar=s',      'A=s',     'b=s',    'binding=s{1,2}',
  'c=s',           'ckpt=s', 'clear',     'cwd',     'C=s',    'dc=s',
  'dl=s',          'e=s',    'h',         'hard',    'help',   'hold_jid=s',
  'hold_jid_ad=s', 'i=s',    'j=s',       'js=s',    'jsv=s',  'l=s',
  'M=s',           'm=s',    'masterq=s', 'N=s',     'notify', 'now=s',
  'o=s',           'P=s',    'p=s',       'pe=s{2}', 'pty=s',  'q=s',
  'R=s',           'r=s',    'sc=s',      'shell=s', 'soft',   'sync=s',
  'S=s',           't=s',    'tc=s',      'terse',   'v=s',    'verify',
  'V',             'w=s',    'wd=s',
);

my %opt = ();
{
  my $cmd_input_from_file_idx = firstidx { $_ eq '-@' } @ARGV;
  if ($cmd_input_from_file_idx >= 0) {
    $opt{'@'} = splice @ARGV, $cmd_input_from_file_idx, 2;
    die "missing argument for -\@ option" if ($opt{'@'} && $opt{'@'} =~ /^-/);
  }
}

GetOptions(\%opt, @spec) or die "usage error";

my $name    = $opt{N} // 'test_job';
my $shell   = $opt{S};
my $err_dir = $opt{e};
my $out_dir = $opt{o};

my $job_id = time;

if ($opt{t}) {

  my $max_instances = $ENV{BGRS_NUM_PROCESSES} // 4;
  say STDERR "NUMBER OF PROCESSES: $max_instances";
  my $pm = Parallel::ForkManager->new($max_instances);

  #stepsize is not implemented
  $opt{t} =~ s/:\d+$//;

  my @range = split(/-/, $opt{t});

  for (my $i = $range[0]; $i <= $range[1]; $i++) {
    my %cl_env = %{
      get_array_env(
        {
          stdout_dir => $out_dir,
          stderr_dir => $err_dir,
          shell      => $shell,
          job_name   => $name,
          job_id     => $job_id,
          range      => [ $range[0], $i, $range[1] ],
          #verbose    => 1,
        }
      )
    };
    %ENV = (%cl_env, %ENV,);
    my @cmd = ($opt{S}, @ARGV);
    my $pid = $pm->start and next;

    sys_redirect([ \@cmd, \%cl_env, $ENV{SGE_STDOUT_PATH}, $ENV{SGE_STDERR_PATH} ]);

    $pm->finish;    # Terminates the child process
  }
  $pm->wait_all_children;
} else {
  my %cl_env = %{
    get_single_env(
      {
        stdout_dir => $out_dir,
        stderr_dir => $err_dir,
        shell      => $shell,
        job_name   => $name,
        job_id     => $job_id,
        #verbose    => 1
      }
    )
  };
  %ENV = (%ENV, %cl_env,);

  my @cmd = ($opt{S}, @ARGV);
  sys_redirect([ \@cmd, \%cl_env, $ENV{SGE_STDOUT_PATH}, $ENV{SGE_STDERR_PATH} ]);

}
say "Your job $job_id (\"$name\") has been submitted";

sub sys_redirect {
  my ($item) = @_;

  my ($cmd_args, $cl_env, $stdout_f, $stderr_f) = @$item;
  my $cmd_args_sq = shell_quote(@$cmd_args);
  my $stdout_f_sq = shell_quote($stdout_f);
  my $stderr_f_sq = shell_quote($stderr_f);

  %ENV = (%ENV, %$cl_env,);
  system("$cmd_args_sq 2>$stderr_f_sq >$stdout_f_sq") == 0 or die "system $cmd_args_sq failed: $?";
  return;
}

#array
#qsub
#-t 1-6
#-S /home/bargs001/perl5/perlbrew/perls/perl-5.14.2/bin/perl
#-N test_env
#-e /home/bargs001/Bio-Grid-Run-SGE/tmp_test/cbpPDIFcC8/tmp/err
#-o /home/bargs001/Bio-Grid-Run-SGE/tmp_test/cbpPDIFcC8/tmp/out
#/home/bargs001/Bio-Grid-Run-SGE/tmp_test/cbpPDIFcC8/tmp/test_env.env.pl
#/home/bargs001/Bio-Grid-Run-SGE/scripts/cl_env.pl
#--worker /home/bargs001/Bio-Grid-Run-SGE/tmp_test/cbpPDIFcC8/tmp/test_env.config.dat

#single
#qsub
#-S /home/bargs001/perl5/perlbrew/perls/perl-5.14.2/bin/perl
#-N goss_omcl_2
#-e /home/bargs001/jobs/2013-02-09_go_semsim_bmrf_omcl/tmp/err
#-o /home/bargs001/jobs/2013-02-09_go_semsim_bmrf_omcl/tmp/out
#/home/bargs001/jobs/2013-02-09_go_semsim_bmrf_omcl/tmp/goss_omcl_2.env.pl
#/home/bargs001/jobs/2013-02-09_go_semsim_bmrf_omcl/cl_calc.pl
#--worker /home/bargs001/jobs/2013-02-09_go_semsim_bmrf_omcl/tmp/goss_omcl_2.config.dat
#--range 14406
#--job_id 35672
#--id 407

