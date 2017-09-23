package Bioinfo::App::Cmd::Fasta::Cmd::GetByID;
use Modern::Perl;
use Moo;
use Bioinfo::Fasta;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;
use IO::All;
use Data::Dumper;

our $VERSION = '0.1.11'; # VERSION: 
# ABSTRACT: my perl module and CLIs for Biology


option input => (
  is  => 'ro',
  required  => 1,
  format  => 's',
  short => 'i',
  doc => 'a file of seq id, one per line'
);


option db => (
  is => 'ro',
  format => 's',
  short => 'd',
  doc => 'fasta file',
);


option output => (
  is => 'ro',
  format => 's',
  short => 'o',
  doc => 'output file',
);


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  $self->options_usage unless (@$args_ref);
  my $input = $self->input;
  my $output = $self->output;
  my $db = $self->db;

  say "input:$input\toutput:$output\tdb:$db";
  my $fas_obj = Bioinfo::Fasta->new(file => $db);
  $fas_obj->get_seqs_batch("$input", $output);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bioinfo::App::Cmd::Fasta::Cmd::GetByID - my perl module and CLIs for Biology

=head1 VERSION

version 0.1.11

=head1 SYNOPSIS

  use Bioinfo::App::Cmd::Fasta::Cmd::GetByID;
  ...

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 input

The input file is a file of seq id(one per line)

=head2 db

path of fasta file

=head2 output

path of output file

=head1 METHODS

=head2 execute

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
