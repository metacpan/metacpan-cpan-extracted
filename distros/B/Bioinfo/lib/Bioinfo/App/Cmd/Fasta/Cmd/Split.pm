package Bioinfo::App::Cmd::Fasta::Cmd::Split;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;
use IO::All;

our $VERSION = '0.1.8'; # VERSION: 
# ABSTRACT: my perl module and CLIs for Biology


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
  doc => ''
);


option outdir => (
  is => 'ro',
  format => 's',
  short => 'o',
  doc => '',
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
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bioinfo::App::Cmd::Fasta::Cmd::Split - my perl module and CLIs for Biology

=head1 VERSION

version 0.1.8

=head1 SYNOPSIS

  use Bioinfo::App::Cmd::Fasta;
  ...

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 input

The input file is a file of fasta format

=head2 num

number of files that the fasta file will be split

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
