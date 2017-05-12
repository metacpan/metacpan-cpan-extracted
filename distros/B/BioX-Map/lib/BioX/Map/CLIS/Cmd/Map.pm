package BioX::Map::CLIS::Cmd::Map;
use Modern::Perl;
use IO::All;
use Carp "confess";
use Moo;
use MooX::Options prefer_commandline => 1, with_config_from_file => 1;
use MooX::Cmd;
use BioX::Map;
use Types::Standard qw(Int Str Bool Enum);

our $VERSION = '0.0.12'; # VERSION:
# ABSTRACT: a wrapper for mapping software


around _build_config_identifier => sub { 'berry' };
around _build_config_prefix => sub { 'biox_map' };


option infile => (
  is        => 'ro',
  format    => 's',
  short     => 'i',
  doc       => "path of one fastq file",
  default   => '',
);


option outfile => (
  is        => 'ro',
  format    => 's',
  short     => 'o',
  doc       => "path of outfile",
  default   => '',
);


option indir => (
  is        => 'ro',
  format    => 's',
  short     => 'I',
  default   => '',
  doc       => "path of indir include fastq file",
);


option outdir => (
  is        => 'ro',
  format    => 's',
  short     => 'O',
  doc       => "path of outdir",
  default   => './',
);


option process_tool => (
  is        => 'ro',
  format    => 'i',
  short     => 'p',
  doc       => "cpu number used by mapping software",
  default   => 1,
);


option process_sample => (
  is        => 'ro',
  format    => 'i',
  short     => 'P',
  doc       => "number of samples running parallel",
  default   => 1,
);


option genome => (
  is        => 'ro',
  format    => 's',
  short     => 'g',
  required  => 1,
  doc       => "path of genome file",
);


option tool => (
  is        => 'ro',
  isa       => Enum['soap', 'bwa'],
  format    => 's',
  short     => 't',
  required  => 1,
  default   => 'soap',
  doc       => "mapping software",
);


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my $stamp = time;
  my $pre_message = "please input parameters, genome is required, either infile or indir is required";
  my ($infile, $indir, $outfile, $outdir) = ($self->infile, $self->indir, $self->outfile, $self->outdir);
  $self->options_usage(1, $pre_message) unless ($infile or $indir);
  my ($genome, $tool, $process_tool, $process_sample) = ($self->genome, $self->tool, $self->process_tool, $self->process_sample);
  my $bm = BioX::Map->new(
    infile          => $infile,
    indir           => $indir,
    outfile         => $outfile,
    outdir          => $outdir,
    genome          => $genome,
    tool            => $tool,
    process_tool    => $process_tool,
    process_sample  => $process_sample,
  );
  $bm->map;
  my $m = time - $stamp;
  say "duration second:" . (time - $stamp) . "\nduration minute:" . (int($m/60));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BioX::Map::CLIS::Cmd::Map - a wrapper for mapping software

=head1 VERSION

version 0.0.12

=head1 SYNOPSIS

  use BioX::Map::CLIS::Cmd::Map;
  BioX::Map::CLIS::Cmd::Map->new_with_cmd;

=head1 DESCRIPTION

  used to mapped a or more sample.

=head1 Attribute

=head2 infile

input file

=head2 outfile

outfile

=head2 indir

input dir that include multiple samples

=head2 outdir

output dir

=head2 process_tool

process number used by soap or bwa

=head2 process_sample

process number used when there are many samples

=head2 genome

path of genome file

=head2 tool

soap or bwa

=head2 execute

=head2 BUILDARGS

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
