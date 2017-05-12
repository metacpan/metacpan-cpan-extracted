package Mtest;


use warnings;
use strict;
use File::Spec;
use Config::Auto;
use Data::Dumper;
use Bio::Grid::Run::SGE::Util qw/my_glob my_sys expand_path my_mkdir expand_path_rel/;
use Cwd;
use Config;
use Bio::Gonzales::Util::Cerial;


use Mouse;

our $VERSION = 0.01_01;

our $RC_FILE = "$ENV{HOME}/.comp_bio_cluster.config";

override 'BUILDARGS' => sub {
  my ($self) = @_;
  my $a = super();

  my $c;
  $c = eval { Config::Auto::parse($RC_FILE) } if ( $RC_FILE && -f $RC_FILE );
  print STDERR Dumper $c;
  if ( $c && !$@ ) {
    print STDERR "Using config from " . $RC_FILE . "\n";
    $a = { %{$c}, %{$a} };
  }

  if ( exists( $a->{'config'} ) ) {
    $c = eval { Config::Auto::parse( $a->{'config'} ) };
    unless ($@) {
      print STDERR "Using config from " . $a->{'config'} . "\n";
      $a = { %{$c}, %{$a} };
    }

  }
  return $a;
};

has 'cmd' => ( is => 'rw', required => 1, isa => 'ArrayRef[Str]' );
has 'no_post_task' => ( is => 'rw' );

has 'tmp_dir'    => ( is => 'rw', lazy_build => 1 );
has 'stderr_dir' => ( is => 'rw', lazy_build => 1 );
has 'stdout_dir' => ( is => 'rw', lazy_build => 1 );
has 'result_dir' => ( is => 'rw', lazy_build => 1 );
has 'log_dir'    => ( is => 'rw', lazy_build => 1 );
has 'idx_dir'    => ( is => 'rw', lazy_build => 1 );
has 'test'       => ( is => 'rw' );
has 'mail'       => ( is => 'rw' );
has 'smtp_server' => ( is => 'rw' );
has 'no_prompt'   => ( is => 'rw' );
has 'lib'         => ( is => 'rw' );

has 'input' => ( is => 'rw', required => 1, isa => 'ArrayRef' );

has 'extra' => ( is => 'rw' );

# one can supply parts or combinations per job
has 'parts' => ( is => 'rw', default => 0 );
has 'combinations_per_job' => ( is => 'rw' );

has 'job_name' => ( is => 'rw', default => 'cluster_job' );
has 'job_id' => ( is => 'rw' );

has 'method' => ( is => 'rw', required => 1 );

has '_worker_config_file' => ( is => 'rw', lazy_build => 1 );
has '_worker_env_script'  => ( is => 'rw', lazy_build => 1 );
has 'submit_bin'          => ( is => 'rw', default    => 'qsub' );
has 'submit_params'       => ( is => 'rw', default    => sub { [] }, isa => 'ArrayRef[Str]' );
has 'perl_bin'            => ( is => 'rw', default    => $Config{perlpath} );
has 'working_dir'         => ( is => 'rw', default    => '.' );

# arguments for the cluster script
has 'args' => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] } );

has 'iterator' => ( is => 'rw', lazy_build => 1 );

sub num_slots { return shift->parts(@_) }

sub _build_log_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->tmp_dir(), 'log' );
}

sub _build_stderr_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->tmp_dir, 'err' );
}

sub _build_stdout_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->tmp_dir, 'out' );
}

sub _build_idx_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->working_dir, 'idx' );
}

sub _build_tmp_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->working_dir, 'tmp' );
}

sub _build_result_dir {
  my ($self) = @_;

  return File::Spec->catfile( $self->working_dir, 'result' );
}

sub BUILD {
  my ( $self, $args ) = @_;

  confess "working dir not correct" unless ( -d $self->working_dir );

  my $curdir = getcwd;
  #chdir $self->working_dir;
  for my $d (qw/working_dir log_dir stderr_dir stdout_dir result_dir tmp_dir idx_dir/) {
    print STDERR "$d - ". $self->working_dir;
    $self->$d( expand_path( $self->$d ) );
    print STDERR " - " . $self->$d(), "\n";
  }
}

1;
