package Bioinfo::PBS;
use Moose;
use Modern::Perl;
use IO::All;
use namespace::autoclean;

our $VERSION = '0.1.1'; # VERSION: 
# ABSTRACT: my perl module and CLIs for Biology


has cpu => (
  is  => 'rw',
  isa => 'Int',
  default => sub {'1'},
  lazy => 1,
);


has name => (
  is  => 'rw',
  isa => 'Str',
  default => sub { 'yanxq' },
  lazy => 1,
);


has cmd => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);


has path => (
  is  => 'rw',
  isa => 'Str',
  default => sub { '$PBS_O_WORKDIR' },
  lazy => 1,
);


has job_id => (
  is  => 'ro',
  writer  => '_set_job_id',
  isa => 'Int',
);


has priority => (
  is  => 'rw',
  isa => 'Int',
  default => sub { '1' },
  lazy => 1,
);

has _sh_name => (
  is  => 'rw',
  isa => 'Str',
);


around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  my %para = @_ == 1 && ref $_[0] ? %{$_[0]} : @_;
  return $class->$orig(%para);
};



sub get_sh {
  my ($self, $sh_name) = @_;
  $sh_name ||= $self->name . "_" . time . ".sh";
  my ($path, $cmd) = ($self->path, $self->cmd);
  my $sh_content =<<EOF;
cd $path
echo "Directory is $path"
NP = `cat \$PBS_NODEFILE|wc -l`
echo \$NP
echo "Work dir is \$PBS_O_WORKDIR"
echo "Excuting Hosts is flowing:"
cat \$PBS_NODEFILE
echo "begin time: `date`"
echo "CMD: $cmd"
$cmd
echo "finish time: `date`"
echo "DONE";
EOF
  io($sh_name)->print($sh_content);
  $self->_sh_name($sh_name);
  say "task setted attr sh_name:". $self->_sh_name;
  return $sh_name;
}


sub qsub {
  my $self = shift;
  my $sh_name = $self->get_sh;
  my ($name, $cpu) = ($self->name, $self->cpu);
  my $qsub_result = `qsub -l nodes=1:ppn=$cpu -N $name $sh_name`;
  say "$qsub_result";
  if ($qsub_result =~/^(\d+?)\./) {
    say "job_id: $1";
    $self->_set_job_id($1);
  } else {
    say "Error: fail to qsub $sh_name; \n $qsub_result";
  }
  return $self;
}


sub wait {
  my $self = shift;
  while ($self->job_stat) {
    sleep(120);
  }
  return 0;
}


sub job_stat {
  my $self = shift;
  my $o = $self->name . ".o" . $self->job_id;
  if (-e $o) {
    my $out = `tail -1 $o`;
    chomp($out);
    if ($out eq "DONE") {
      return 0;
    } else {
      return 1;
    }
  } else {
    return -1;
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bioinfo::PBS - my perl module and CLIs for Biology

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

  use Bioinfo::PBS;
  my $para =  {
    cpu => 2,
    name => 'blast',
    cmd => 'ls -alh; pwd',
  };
  my $pbs_obj = Bioinfo::PBS->new($para);
  $pbs_obj->qsub;

=head1 DESCRIPTION

This module is created to simplify process of task submitting in PBS system,
and waiting for the finish of multiple tasks.

=head1 ATTRIBUTES

=head2 cpu

cpu number that will apply

=head2 name

prefix of output of STANDARD and ERR

=head2 cmd

the command that will be submitted to cluster

=head2 path

the path that cmd will execute in

=head2 job_id

the job id of qsub

=head2 priority

the priority during the process of Batch submmit in Queue

=head1 METHODS

=head2 get_sh

get shell file that will used in qsub

=head2 qsub

submit the program to cluster

=head2 wait

wait until the program finished in cluster

=head2 job_stat

get the status of job. C<0> will be return if the job has completed

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
