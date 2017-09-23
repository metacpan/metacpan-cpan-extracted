package Bioinfo::App::Cmd::Blast::Cmd::SplitSubmit;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;
use IO::All;
use Bioinfo::PBS::Queue;

our $VERSION = '0.1.11'; # VERSION: 
# ABSTRACT: submit blast after splitting a fasta file into multiple files;


option input => (
  is  => 'ro',
  required  => 1,
  format  => 's',
  short => 'i',
  doc => 'a file of fasta format'
);


option num => (
  is  => 'ro',
  format  => 'i',
  short => 'n',
  default => sub { '6' },
  doc => 'number of files that the fasta file will be split'
);


option db => (
  is  => 'rw',
  format => 's',
  short => 'd',
  default => sub { 'nr_plant' },
  doc => 'the database that blast will use',
);


option type => (
  is  => 'rw',
  format => 's',
  short => 't',
  default => sub { 'pbs' },
  doc => "where the blast will be runned, enum['local','pbs']. default:'pbs'"
);


option blast => (
  is => 'rw',
  format => 's',
  short => 'b',
  default => sub { 'blastp' },
  doc => 'which blast program will be used',
);


option cpu => (
  is => 'ro',
  format => 'i',
  short => 'c',
  default => sub { '4' },
  doc => "cpu number used in one node"
);


option outdir => (
  is => 'ro',
  format => 's',
  short => 'o',
  default => sub { './' },
  doc => 'outdir of split files',
);


option prefix => (
  is => 'ro',
  format => 's',
  short => 'p',
  default => sub { '' },
  doc => 'the prefix of the split file',
);


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  $self->options_usage unless (@$args_ref);
  my $input = $self->input;
  my $outdir = $self->outdir;
  my $num = $self->num;
  my $prefix = $self->prefix;
  system("mkdir -p $outdir") unless -e $outdir;
  my %id2seq;
  my $io_fa = io($input)->chomp;
  my ($total_base, $seqid) = (0, '');
  while (defined (my $line = $io_fa->getline)) {
    if ($line =~/^>/) {
      $seqid = $line;
    } else {
      $id2seq{$seqid} .= $line;
      $total_base += length($line);
    }
  }
  say "number of files:$num\t prefix:$prefix\toutdir:$outdir";
  say "total base: $total_base";
  my $file_base = int($total_base / $num) + 2;
  my ($file_base_tmp, $index_tmp) = (0, 1);
  my $single_file_name = "$outdir/$prefix$index_tmp.fa";
  my $single_file_content = "";
  for my $id (keys %id2seq) {
    if ($file_base_tmp < $file_base) {
      $single_file_content .= sprintf("%s\n%s\n", $id, $id2seq{$id});
      $file_base_tmp += length($id2seq{$id});
    } else {
      io($single_file_name)->print("$single_file_content");
      say "$single_file_name\t$file_base_tmp";

      # set next file parameter
      $single_file_content = sprintf("%s\n%s\n", $id, $id2seq{$id});
      $file_base_tmp = length($id2seq{$id});
      $index_tmp++;
      $single_file_name = "$outdir/$prefix$index_tmp.fa";
    }
  }

  # the last one file
  if ($file_base_tmp < $file_base) {
    $single_file_name = "$outdir/$prefix$index_tmp.fa";
    io($single_file_name)->print("$single_file_content");
    say "$single_file_name\t$file_base_tmp";
  }
  say "finished to split $input, outdir is :$outdir";
  if ($self->type eq 'pbs') {
    $self->submit_pbs;
  } else {
    $self->local_blast;
  }
}

# submit PBS queue
sub submit_pbs {
  my $self = shift;
  my ($input, $outdir, $cpu, $db) = ($self->input, $self->outdir, $self->cpu, $self->db);
  my @io_fas = io("$outdir")->filter( sub {
      $_->filename =~/\.fa/;
    }
  )->all_files;

  my $queue_name = io($input)->filename;
  $queue_name =~s/\.fa|\.pep|\.fasta//;
  say "PBS Queue name: $queue_name";
  chdir "$outdir";
  my $pbs = Bioinfo::PBS::Queue->new(name => $queue_name);
  for my $fa (@io_fas) {
    my $fa_name = $fa->filename;
    my $cmd = "blastp -query $fa_name -out $fa_name.blast -db $db -outfmt 5 -evalue 1e-5 -num_threads $cpu -max_target_seqs 10";
    $fa_name =~s/\.fa|\.pep|\.fasta//;
    my $para = {
      cpu => $cpu,
      name => $fa_name,
      cmd => "$cmd",
    };
    $pbs->add_tasks($para);
  }
  $pbs->execute;
  system("cat *.blast >$queue_name.blast");
  say "finished all blast";
}

sub local_blast {
  my $self = shift;
  my ($input, $outdir, $cpu, $db) = ($self->input, $self->outdir, $self->cpu, $self->db);
  my @io_fas = io("$outdir")->filter( sub {
      $_->filename =~/\.fa/;
    }
  )->all_files;

  my $in_name = io($input)->filename;
  $in_name =~s/\.fa|\.fasta|\.pep//;
  chdir "$outdir";
  use Parallel::ForkManager;
  my $pm = Parallel::ForkManager->new($cpu);
  LOOP_DATA:
  for my $fa (@io_fas) {
    my $pid = $pm->start and next LOOP_DATA;
    my $fa_name = $fa->filename;
    my $cmd = "blastp -query $fa_name -out $fa.xml -db $db -outfmt 5 -evalue 1e-5 -num_threads $cpu -max_target_seqs 10";
    system($cmd);
    $pm->finish;
  }
  $pm->wait_all_chilren;
  system("cat *.blast >$in_name.xml");
  say "finished all";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bioinfo::App::Cmd::Blast::Cmd::SplitSubmit - submit blast after splitting a fasta file into multiple files;

=head1 VERSION

version 0.1.11

=head1 SYNOPSIS

  use Bioinfo::App::Cmd::Blast::Cmd::SplitSubmit;

  Bioinfo::App::Cmd::Blast::Cmd::SplitSubmit->new_with_cmd;

=head1 DESCRIPTION

this module splits a fasta file into multiple files, then submit these files on parallel.

=head1 ATTRIBUTES

=head2 input

The input file is a file of fasta format

=head2 num

number of files that the fasta file will be split

=head2 db

the database that blast will use

=head2 type

=head2 blast

=head2 cpu

=head2 outdir

=head2 prefix

the prefix of the split file

=head1 METHODS

=head2 execute

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
