package Bio::AssemblyImprovement::Scaffold::Descaffold;
# ABSTRACT: Given a fasta file as input, output a descaffolded multi-fasta file.




use Moose;
use Bio::SeqIO;

has 'input_assembly'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'output_filename' => ( is => 'ro', isa => 'Str', builder  => '_build_output_filename', lazy => 1 );
has '_output_prefix'  => ( is => 'ro', isa => 'Str', default  => "descaffolded" );

sub _build_output_filename
{
  my ($self) = @_;
  return $self->input_assembly.".".$self->_output_prefix;
}

sub run
{
  my ($self) = @_;
  
  my $fasta_obj     = Bio::SeqIO->new( -file => $self->input_assembly, -format => 'Fasta');
  my $out_fasta_obj = Bio::SeqIO->new( -file => "+>".$self->output_filename, -format => 'Fasta');
  
  while(my $seq = $fasta_obj->next_seq())
  {
    my @split_sequences = split(/N+/,$seq->seq());
    my $sequence_counter = 1;
    for my $split_sequence (@split_sequences)
    {
      next if($split_sequence eq "");
      $out_fasta_obj->write_seq(Bio::Seq->new( -display_id => $seq->display_id."_".$sequence_counter, -seq => $split_sequence ));
      $sequence_counter++;
    }
  }
  1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::AssemblyImprovement::Scaffold::Descaffold - Given a fasta file as input, output a descaffolded multi-fasta file.

=head1 VERSION

version 1.160490

=head1 SYNOPSIS

Given a fasta file as input, output a descaffolded multi-fasta file.

   use Bio::AssemblyImprovement::Scaffold::Descaffold;

   my $descaffold_obj = Bio::AssemblyImprovement::Scaffold::Descaffold->new(
     input_assembly => 'contigs.fa'
   );

   $descaffold_obj->run();

=head1 METHODS

=head2 run

Descaffold a FASTA file.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
