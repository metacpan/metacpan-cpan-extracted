package Bio::ASN1::Sequence::Indexer;
$Bio::ASN1::Sequence::Indexer::VERSION = '1.73';
use utf8;
use strict;
use warnings;
use Carp qw(carp croak);
use Bio::ASN1::Sequence;
use Bio::Index::AbstractSeq;
use parent qw(Bio::Index::AbstractSeq);

# ABSTRACT: Indexes NCBI Sequence files.
# AUTHOR:   Dr. Mingyi Liu <mingyiliu@gmail.com>
# OWNER:    2005 Mingyi Liu
# OWNER:    2005 GPC Biotech AG
# OWNER:    2005 Altana Research Institute
# LICENSE:  Perl_5



# TODO: Should this be deprecated?

sub _version
{
  return $Bio::Index::AbstractSeq::VERSION;
}


sub _type_stamp
{
  return '__Sequence_ASN1__';
}


sub _index_file
{
  my($self, $file, $idx) = @_;
  my $position;
  open(IN, $file) || $self->throw("Can't open $file - $!");
  local $/ = "Seq-entry ::= set {";
  while(<IN>)
  {
    chomp;
    while(/[,{}]\s+accession\s*"([^"]+)"\s+[,{}]/ig) # add both dna and protein
    {
      $self->add_record($1, $idx, $position);
    }
    $position = tell(IN) - 19; # $/'s length
  }
  close(IN);
  return 1;
}


sub _file_format
{
  return 'sequence';
}



sub fetch_hash
{
  my ($self, $seqid) = @_;
  if (my $seq = $self->db->{$seqid})
  {
    my ($fileno, $position) = $self->unpack_record($seq);
    my $parser = Bio::ASN1::Sequence->new('fh' => $self->_file_handle($fileno));
    seek($parser->fh, $position, 0);
    return $parser->next_seq;
  }
}


sub _file_handle {
  my( $self, $i ) = @_;

  unless ($self->{'_filehandle'}[$i]) {
    my @rec = $self->unpack_record($self->db->{"__FILE_$i"})
      or $self->throw("Can't get filename for index : $i");
    my $file = $rec[0];
    local *FH;
    open *FH, $file or $self->throw("Can't read file '$file' : $!");
    $self->{'_filehandle'}[$i] = *FH; # Cache filehandle
  }
  return $self->{'_filehandle'}[$i];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::ASN1::Sequence::Indexer - Indexes NCBI Sequence files.

=head1 VERSION

version 1.73

=head1 SYNOPSIS

  use Bio::ASN1::Sequence::Indexer;

  # creating & using the index is just a few lines
  my $inx = Bio::ASN1::Sequence::Indexer->new(
    -filename => 'seq.idx',
    -write_flag => 'WRITE'); # needed for make_index call, but if opening
                             # existing index file, don't set write flag!
  $inx->make_index('seq1.asn', 'seq2.asn');
  my $seq = $inx->fetch('AF093062'); # Bio::Seq obj for Sequence (doesn't work yet)
  # alternatively, if one prefers just a data structure instead of objects
  $seq = $inx->fetch_hash('AF093062'); # a hash produced by Bio::ASN1::Sequence
                            # that contains all data in the Sequence record

=head1 DESCRIPTION

Bio::ASN1::Sequence::Indexer is a Perl Indexer for NCBI Sequence genome
databases. It processes an ASN.1-formatted Sequence record and stores the
file position for each record in a way compliant with Bioperl standard (in
fact its a subclass of Bioperl's index objects).

Note that this module does not parse record, because it needs to run fast and
grab only the gene ids.  For parsing record, use Bio::ASN1::Sequence.

As with Bio::ASN1::Sequence, this module is best thought of as beta version -
it works, but is not fully tested.

=head1 METHODS

=head2 fetch

  Parameters: $geneid - id for the Sequence record to be retrieved
  Example:    my $hash = $indexer->fetch(10); # get Sequence #10
  Function:   fetch the data for the given Sequence id.
  Returns:    A Bio::Seq object produced by Bio::SeqIO::sequence
  Notes:      Bio::SeqIO::sequence does not exist and probably won't
                exist for a while!  So call fetch_hash instead

=head2 fetch_hash

  Parameters: $seqid - id for the Sequence record to be retrieved
  Example:    my $hash = $indexer->fetch_hash('AF093062');
  Function:   fetch a hash produced by Bio::ASN1::Sequence for given id
  Returns:    A data structure containing all data items from the Sequence
                record.
  Notes:      Alternative to fetch()

=head1 INTERNAL METHODS

=head2 _version

=head2 _type_stamp

=head2 _index_file

=head2 _file_format

=head2 _file_handle

  Title   : _file_handle
  Usage   : $fh = $index->_file_handle( INT )
  Function: Returns an open filehandle for the file
            index INT.  On opening a new filehandle it
            caches it in the @{$index->_filehandle} array.
            If the requested filehandle is already open,
            it simply returns it from the array.
  Example : $fist_file_indexed = $index->_file_handle( 0 );
  Returns : ref to a filehandle
  Args    : INT
  Notes   : This function is copied from Bio::Index::Abstract. Once that module
              changes file handle code like I do below to fit perl 5.005_03, this
              sub would be removed from this module

=head1 PREREQUISITE

Bio::ASN1::Sequence, Bioperl and all dependencies therein.

=head1 INSTALLATION

Same as Bio::ASN1::EntrezGene

=head1 SEE ALSO

Please check out perldoc for Bio::ASN1::EntrezGene for more info.

=head1 CITATION

Liu, Mingyi, and Andrei Grigoriev. "Fast parsers for Entrez Gene."
Bioinformatics 21, no. 14 (2005): 3189-3190.

=head1 OPERATION SYSTEMS SUPPORTED

Any OS that Perl & Bioperl run on.

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/Support.html    - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/bio-asn1-entrezgene/issues

=head1 AUTHOR

Dr. Mingyi Liu <mingyiliu@gmail.com>

=head1 COPYRIGHT

This software is copyright (c) 2005 by Mingyi Liu, 2005 by GPC Biotech AG, and 2005 by Altana Research Institute.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
