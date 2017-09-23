package Bioinfo::PBS::Queue;
use Moose;
use Modern::Perl;
use Parallel::ForkManager;
use IO::All;
use List::Util 'uniq';
use namespace::autoclean;

our $VERSION = '0.1.11'; # VERSION:
# ABSTRACT: used to submit a batch of task to Torque cluster


has tasks => (
  is  => 'rw',
  isa => 'ArrayRef[Bioinfo::PBS]',
  default => sub { [] },
  traits => ['Array'],
  handles => {
    _add_tasks => 'push',
    all_tasks => 'elements',
    filter_tasks => 'grep',
    count_tasks => 'count',
    pop_tasks => 'pop',
  },
);



sub add_tasks {
  my $self = shift;
  my $type = ref $_[0];
  if ($type eq 'Bioinfo::PBS') {
    $self->_add_tasks(@_);
  } elsif ($type eq 'Bioinfo::PBS::Queue') {
    $self->_add_tasks($_[0]->all_tasks);
  } elsif ($type eq 'HASH') {
    use Bioinfo::PBS;
    $self->_add_tasks(Bioinfo::PBS->new($_)) for @_;
  }
}

has name => (
  is  => 'rw',
  isa => 'Str',
  default => sub { 'pbs' },
);

has parallel => (
  is  => 'rw',
  isa => 'Int',
  lazy => 1,
  default => sub { shift->count_tasks }
);

has _log => (
  is  => 'rw',
  isa => 'IO::All',
  default => sub { io(shift->name . ".log") },
  lazy => 1,
);

has run_queue => (
  is  => 'ro',
  isa => 'ArrayRef[Bioinfo::PBS]',
  default => sub { [] },
  traits => ['Array'],
  handles => {
    run_queue_add => 'push',
    run_queue_tasks => 'elements',
    run_queue_count => 'count',
  },
);

has finished_queue => (
  is  => 'ro',
  isa => 'ArrayRef[Bioinfo::PBS]',
  default => sub { [] },
  lazy  => 1,
  traits => ['Array'],
  handles => {
    finished_queue_add => 'push',
    finished_queue_tasks => 'elements',
    finished_queue_filter => 'grep',
  },
);

has stage => (
  is  => 'ro',
  writer => "_set_writer",
  isa => 'Int',
  default => sub { '1' },
  lazy => 1,
);


sub execute {
  my $self = shift;
  my @tasks =  $self->all_tasks;
  my $task_run_num = $self->parallel;
  my @stages = uniq (map { $_->priority } @tasks);
  my $content = "name\tcpu\tpriority\tsh_name\tjob_id\tstat\tcmd\n";
  $self->_log->lock->append($content)->unlock;
  for my $stage (@stages) {
    $self->_log->lock->append("# Stage$stage: running\n")->unlock;
    say "Stage $stage";
    my @stage_tasks = $self->filter_tasks( sub {$_->priority == $stage} );
    my $paralell_num = $task_run_num || ($#stage_tasks + 1);
    my $pm = Parallel::ForkManager->new($paralell_num);
    DATA_LOOP:
    for my $task (@stage_tasks) {
      sleep 1;
      my ($name, $cpu, $cmd, $priority) = ($task->name, $task->cpu, $task->cmd, $task->priority);
      my $pid = $pm->start and next DATA_LOOP;
      say "$name will be submitted\n";
      $task->qsub->wait;
      say "$name  finished\n";
      my ($stat, $job_id, $sh_name) = ($task->job_stat, $task->job_id, $task->_sh_name);
      $content = "$name\t$cpu\t$priority\t$sh_name\t$job_id\t$stat\t$cmd\n";
      #say "$content";
      #my $log_name = $self->name . ".log";
      #io($log_name)->lock->append($content)->unlock;
      $self->_log->lock->append($content)->unlock;
      $pm->finish;
    }
    $pm->wait_all_children;
    say "finished the whole project";
  }
}

sub log {
  my ($self, $content) = @_;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bioinfo::PBS::Queue - used to submit a batch of task to Torque cluster

=head1 VERSION

version 0.1.11

=head1 SYNOPSIS

  use Bioinfo::PBS;
  use Bioinfo::PBS::Queue;
  my $para =  {
    cpu => 2,
    name => 'blast',
    cmd => 'ls -alh; pwd',
  };
  my $pbs_obj = Bioinfo::PBS->new($para);

  # three tasks are running at the same time
  my $queue_obj = Bioinfo::PBS::Queue->new(name => 'blastnr', parallel => 3);

  # all tasks will be running at the same time if parallel is not setted
  my $queue_obj = Bioinfo::PBS::Queue->new(name => 'blastnr');
  $queue_obj->add_tasks($pbs_obj);
  $queue_obj->add_tasks($pbs_obj);
  $queue_obj->execute;

=head1 DESCRIPTION

This module is created to simplify process of task submitting in PBS system,
and waiting for the finish of multiple tasks.

=head1 ATTRIBUTES

=head2 tasks

cpu number that will apply

=head2 add_tasks

one or more object of Bioinfo::PBS can be added to queue.
if a Bioinfo::PBS::Queque be added, all its tasks are added.
if a hashref can be passed, a object of Bioinfo::PBS will be
created and added to this queue, for example:
{cpu =>2, name =>'blast', cmd=>"ls -alh", priority=>1}

=head1 METHODS

=head2 execute

run all tasks in the queue by the order

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
