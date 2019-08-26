# -*-CPerl-*-
# Last changed Time-stamp: <2019-08-25 20:54:13 mtw>

# Bio::RNA::RNAaliSplit.pm: Handler for horizontally splitting alignments

package Bio::RNA::RNAaliSplit;

use version; our $VERSION = qv('0.11');
use Carp;
use Data::Dumper;
use Moose;
use Moose::Util::TypeConstraints;
use Path::Class;
use File::Basename;
use IPC::Cmd qw(can_run run);
#use Bio::AlignIO;
use Storable 'dclone';
use File::Path qw(make_path);
use diagnostics;

extends 'Bio::RNA::RNAaliSplit::AliHandler';

has 'alignment_aln' => (
			is => 'rw',
			isa => 'Path::Class::File',
			predicate => 'has_aln_file',
			init_arg => undef,
		       );

has 'alignment_stk' => (
			is => 'rw',
			isa => 'Path::Class::File',
			predicate => 'has_stk_file',
			init_arg => undef,
		       );

has 'hammingdistN' => (
		       is => 'rw',
		       isa => 'Num',
		       default => '-1',
		       predicate => 'has_hammingN',
		       init_arg => undef,
		      );

has 'hammingdistX' => (
		       is => 'rw',
		       isa => 'Num',
		       default => '-1',
		       predicate => 'has_hammingX',
		       init_arg => undef,
		      );


with 'FileDirUtil';

sub BUILD {
    my $self = shift;
    my $this_function = (caller(0))[3];
    confess "ERROR [$this_function] \$self->ifile not available"
      unless ($self->has_ifile);
    $self->alignment({-file => $self->ifile,
		      -format => $self->format,
		      -displayname_flat => 1} );
    $self->next_aln($self->alignment->next_aln);
    $self->next_aln->set_displayname_safe();
    $self->_get_alen();
    $self->_get_nrseq();
    unless($self->has_odir){
      my $odir_name = "as";
      $self->odir( [$self->ifile->dir,$odir_name] );
    }
    my @created = make_path($self->odir, {error => \my $err});
    confess "ERROR [$this_function] could not create output directory $self->odir"
      if (@$err);
    $self->set_ifilebn;

    # dump ifile as aln and stk in ClustalW format to odir/input
    my $iodir = $self->odir->subdir('input');
    mkdir($iodir);
    my $ialnfile = file($iodir,$self->ifilebn.".aln");
    my $istkfile = file($iodir,$self->ifilebn.".stk");
    my $alnio = Bio::AlignIO->new(-file   => ">$ialnfile",
				  -format => "clustalw",
				  -flush  => 0,
				  -displayname_flat => 1 );
    my $stkio = Bio::AlignIO->new(-file   => ">$istkfile",
				  -format => "stockholm",
				  -flush  => 0,
				  -displayname_flat => 1 );
    my $aln2 = $self->next_aln->select_noncont((1..$self->next_aln->num_sequences));
    my $stk2 = $self->next_aln->select_noncont((1..$self->next_aln->num_sequences));
    $alnio->write_aln($aln2);
    $stkio->write_aln($stk2);
    $self->alignment_aln($ialnfile);
    $self->alignment_stk($istkfile);
    # end dump ifile

    if ($self->next_aln->num_sequences == 2){ $self->_hamming() }
  }

sub dump_subalignment {
  my ($self,$alipathsegment,$token,$what) = @_;
  my $this_function = (caller(0))[3];
  my ($aln,$aln2,$name);

  croak "ERROR [$this_function] argument 'token' not provided"
    unless (defined($token));

  # create output path
  my $ids = join "_", @$what;
  unless (defined($alipathsegment)){$alipathsegment = "tmp"}
  my $oodir = $self->odir->subdir($alipathsegment);
  mkdir($oodir);

  # create info file
  my $oinfofile = file($oodir,$token.".info");
  open my $oinfo, ">", $oinfofile or die $!;
  foreach my $entry (@$what){
    my $key = $entry-1;
    my $val = ${$self->next_aln}{_order}->{$key};
    print $oinfo join "\t", ($entry, $val, "\n");
  }
  close($oinfo);

  # create subalignment in Clustal and Stockholm format
  my $oalifile_clustal = file($oodir,$token.".aln");
  my $oalifile_stockholm = file($oodir,$token.".stk");
  my $oali_clustal = Bio::AlignIO->new(-file   => ">$oalifile_clustal",
				       -format => "ClustalW",
				       -flush  => 0,
				       -displayname_flat => 1 );
  my $oali_stockholm = Bio::AlignIO->new(-file   => ">$oalifile_stockholm",
					 -format => "Stockholm",
					 -flush  => 0,
					 -displayname_flat => 1 );
  $aln = $self->next_aln->select_noncont(@$what);
  $oali_clustal->write_aln( $aln );
  $oali_stockholm->write_aln( $aln );

  # create subalignment fasta file
  my $ofafile = file($oodir,$token.".fa");
  my $ofa = Bio::AlignIO->new(-file   => ">$ofafile",
			      -format => "fasta",
			      -flush  => 0,
			      -displayname_flat => 1 );
  $aln2 = $aln->remove_gaps;
  $ofa->write_aln( $aln2 );

  # extract sequences from alignment and dump to .seq file
  # NOTE that these sequences do contain gap symbols, intentionally (!)
  # these can then be replaced by Ns to compute eg hamming distance
  my $oseqfile = file($oodir,$token.".seq");
  open my $seqfile, ">", $oseqfile or die $!;
  foreach my $seq ($aln->each_seq) {
    print $seqfile $seq->seq,"\n";
  }
  close($seqfile);

  return ( $oalifile_clustal,$oalifile_stockholm );
}

sub _hamming {
  my $self = shift;
  my $this_function = (caller(0))[3];
  my $hamming = -1;
  croak "ERROR [$this_function] cannot compute Hamming distance for $self->next_aln->num_sequences sequences"
    if ($self->next_aln->num_sequences != 2);

  my $aln =  $self->next_aln->select_noncont((1,2));

  # compute Hamming distance of the aligned sequences, replacing gaps with Ns
  my $alnN = dclone($aln);
  croak("ERROR [$this_function] cannot replace gaps with Ns")
    unless ($alnN->map_chars('-','N') == 1);
  my $seq1 = $alnN->get_seq_by_pos(1)->seq;
  my $seq2 = $alnN->get_seq_by_pos(2)->seq;
  croak "ERROR [$this_function] sequence length differs"
    unless(length($seq1)==length($seq2));
  my $hammingN = ($seq1 ^ $seq2) =~ tr/\001-\255//;
  $self->hammingdistN($hammingN);

#  print $self->ifilebn,":\n";
#  print ">>s1: $seq1\n";
#  print ">>s2: $seq2\n";
#  print "** dhN = ".$self->hammingdistN."\n";
#  print "+++\n";
}

no Moose;



=head1 NAME

Bio::RNA::RNAaliSplit - Split and deconvolute structural RNA multiple
sequence alignments

=head1 VERSION

Version 0.11

=cut

=head1 SYNOPSIS

This module is a L<Moose> handler for horizontal splitting and
evaluation of structural RNA multiple sequence alignments. It employs
third party tools (RNAalifold, RNAz, R-scape) for classification of
subalignments, each folding into a common consensus structure.

=head1 AUTHOR

Michael T. Wolfinger, C<< <michael at wolfinger.eu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-rna-rnaalisplit at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-RNA-RNAaliSplit>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::RNA::RNAaliSplit


You can also look for information at:

=over 2

=item * metaCPAN

L<https://metacpan.org/release/Bio-RNA-RNAaliSplit>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-RNAaliSplit>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2017-2019 Michael T. Wolfinger <michael@wolfinger.eu> and
<michael.wolfinger@univie.ac.at>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
L<http://www.gnu.org/licenses/>.

=cut

1; # End of Bio::RNA::RNAaliSplit
