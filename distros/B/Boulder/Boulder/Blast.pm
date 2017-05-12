package Boulder::Blast;
# WUBLAST/NCBI BLAST file format parsing

=head1 NAME

Boulder::Blast - Parse and read BLAST files

=head1 SYNOPSIS

  use Boulder::Blast;

  # parse from a single file
  $blast = Boulder::Blast->parse('run3.blast');

  # parse and read a set of blast output files
  $stream = Boulder::Blast->new('run3.blast','run4.blast');
  while ($blast = $stream->get) {
     # do something with $blast object
  }

  # parse and read a whole directory of blast runs
  $stream = Boulder::Blast->new(<*.blast>);
  while ($blast = $stream->get) {
     # do something with $blast object
  }

  # parse and read from STDIN
  $stream = Boulder::Blast->new;
  while ($blast = $stream->get) {
     # do something with $blast object
  }

  # parse and read as a filehandle
  $stream = Boulder::Blast->newFh(<*.blast>);
  while ($blast = <$stream>) {
     # do something with $blast object
  }

  # once you have a $blast object, you can get info about it:      
  $query = $blast->Blast_query;
  @hits  = $blast->Blast_hits;
  foreach $hit (@hits) {
     $hit_sequence = $hit->Name;    # get the ID
     $significance = $hit->Signif;  # get the significance
     @hsps = $hit->Hsps;            # list of HSPs
     foreach $hsp (@hsps) {
       $query   = $hsp->Query;      # query sequence
       $subject = $hsp->Subject;    # subject sequence
       $signif  = $hsp->Signif;     # significance of HSP
     }
  }


=head1 DESCRIPTION

The I<Boulder::Blast> class parses the output of the B<Washington
University (WU)> or National Cenber for Biotechnology Information
(NCBI) series of BLAST programs and turns them into I<Stone> records.
You may then use the standard Stone access methods to retrieve
information about the BLAST run, or add the information to a Boulder
stream.

The parser works equally well on the contents of a static file, or on
information read dynamically from a filehandle or pipe.

=head1 METHODS

=head2 parse() Method

    $stone = Boulder::Blast->parse($file_path);
    $stone = Boulder::Blast->parse($filehandle);

The I<parse()> method accepts a path to a file or a filehandle, parses
its contents, and returns a Boulder Stone object.  The file path may
be absolute or relative to the current directgly.  The filehandle may
be specified as an IO::File object, a FileHandle object, or a
reference to a glob (C<\*FILEHANDLE> notation).  If you call
I<parse()> without any arguments, it will try to parse the contents of
standard input.

=head2 new() Method

    $stream = Boulder::Blast->new;
    $stream = Boulder::Blast->new($file [,@more_files]);
    $stream = Boulder::Blast->new(\*FILEHANDLE);

If you wish, you may create the parser first with I<Boulder::Blast>
I<new()>, and then invoke the parser object's I<parse()> method as
many times as you wish to, producing a Stone object each time.

=head1 TAGS

The following tags are defined in the parsed Blast Stone object:

=head2 Information about the program

These top-level tags provide information about the version of the
BLAST program itself.

=over 4

=item Blast_program

The name of the algorithm used to run the analysis.  Possible values
include:

	blastn
	blastp
	blastx
	tblastn
	tblastx
	fasta3
	fastx3
	fasty3
	tfasta3
	tfastx3
	tfasty3

=item Blast_version

This gives the version of the program in whatever form appears
on the banner page, e.g. "2.0a19-WashU".

=item Blast_program_date

This gives the date at which the program was compiled, if and
only if it appears on the banner page.

=back

=head2 Information about the run

These top-level tags give information about the particular run, such
as the parameters that were used for the algorithm.

=over 4

=item Blast_run_date

This gives the date and time at which the similarity analysis
was run, in the format "Fri Jul  6 09:32:36 1998"

=item Blast_parms

This points to a subrecord containing information about the
algorithm's runtime parameters.  The following subtags are
used.  Others may be added in the future:

	Hspmax		the value of the -hspmax argument
	Expectation	the value of E
	Matrix		the matrix in use, e.g. BLOSUM62
	Ctxfactor	the value of the -ctxfactor argument
	Gapall		The value of the -gapall argument

=back

=head2 Information about the query sequence and subject database

Thse top-level tags give information about the query sequence and the
database that was searched on.

=over 4

=item Blast_query

The identifier for the search sequence, as defined by the
FASTA format.  This will be the first set of non-whitespace
characters following the ">" character.  In other words, the search
sequence "name".

=item Blast_db

The Unix filesystem path to the subject database.

=item Blast_db_title

The title of the subject database.

=back

=head2 The search results: the I<Blast_hits> tag.

Each BLAST hit is represented by the tag I<Blast_hits>.  There may be
zero, one, or many such tags.  They will be presented in reverse
sorted order of significance, i.e. most significant hit first.

Each I<Blast_hits> tag is a Stone subrecord containing the following
subtags:

=over 4

=item Name

The name/identifier of the sequence that was hit.

=item Length

The total length of the sequence that was hit

=item Signif

The significance of the hit.  If there are multiple HSPs in the hit,
this will be the most significant (smallest) value.

=item Identity

The percent identity of the hit.  If there are multiple HSPs, this
will be the one with the highest percent identity.

=item Expect

The expectation value for the hit.  If there are multiple HSPs, this
will be the lowest expectation value in the set.

=item Hsps

One or more sub-sub-tags, pointing to a nested record containing
information about each high-scoring segment pair (HSP).  See the next
section for details.

=back

=head2 The Hsp records: the I<Hsps> tag

Each I<Blast_hit> tag will have at least one, and possibly several
I<Hsps> tags, each one corresponding to a high-scoring segment pair
(HSP).  These records contain detailed information about the hit,
including the alignments.  Tags are as follows:

=over 4

=item Signif

The significance (P value) of this HSP.

=item Bits

The number of bits of significance.

=item Expect

Expectation value for this HSP.

=item Identity

Percent identity.
	
=item Positives

Percent positive matches.

=item Score

The Smith-Waterman alignment score.

=item Orientation

The word "plus" or "minus".  This tag is only present for nucleotide
searches, when the reverse complement match may be present.

=item Strand

Depending on algorithm used, indicates complementarity of match and
possibly the reading frame.  This is copied out of the blast report.
Possibilities include:

 "Plus / Minus" "Plus / Plus" -- blastn algorithm
 "+1 / -2" "+2 / -2"	     -- blastx, tblastx

=item Query_start

Position at which the HSP starts in the query sequence (1-based
indexing).

=item Query_end

Position at which the HSP stops in the query sequence.

=item Subject_start

Position at which the HSP starts in the subject (target) sequence.

=item Subject_end

Position at which the HSP stops in the subject (target) sequence.

=item Query, Subject, Alignment

These three tags contain strings which, together, create the gapped
alignment of the query sequence with the subject sequence.

For example, to print the alignment of the first HSP of the first
match, you might say:

  $hsp = $blast->Blast_hits->Hsps;
  print join("\n",$hsp->Query,$hsp->Alignment,$hsp->Subject),"\n";

=back

See the bottom of this manual page for an example BLAST run.

=head1 CAVEATS

This module has been extensively tested with WUBLAST, but very little
with NCBI BLAST.  It probably will not work with PSI Blast or other
variants.

The author plans to adapt this module to parse other formats, as well
as non-BLAST formats such as the output of Fastn.

=head1 SEE ALSO

L<Boulder>, L<Boulder::GenBank>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 1998-1999 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=head1 EXAMPLE BLASTN RUN

This output was generated by the I<quickblast.pl> program, which is
located in the F<eg/> subdirectory of the I<Boulder> distribution
directory.  It is a typical I<blastn> (nucleotide->nucleotide) run;
however long lines (usually DNA sequences) have been truncated.  Also
note that per the Boulder protocol, the percent sign (%) is escaped in
the usual way.  It will be unescaped when reading the stream
back in.

 Blast_run_date=Fri Nov  6 14:40:41 1998
 Blast_db_date=2:40 PM EST Nov 6, 1998
 Blast_parms={
   Hspmax=10
   Expectation=10
   Matrix=+5,-4
   Ctxfactor=2.00
 }
 Blast_program_date=05-Feb-1998
 Blast_db= /usr/tmp/quickblast18202aaaa
 Blast_version=2.0a19-WashU
 Blast_query=BCD207R
 Blast_db_title= test.fasta
 Blast_query_length=332
 Blast_program=blastn
 Blast_hits={
   Signif=3.5e-74
   Expect=3.5e-74,
   Name=BCD207R
   Identity=100%25
   Length=332
   Hsps={
     Subject=GTGCTTTCAAACATTGATGGATTCCTCCCCTTGACATATATATATACTTTGGGTTCCCGCAA...
     Signif=3.5e-74
     Length=332
     Bits=249.1
     Query_start=1
     Subject_end=332
     Query=GTGCTTTCAAACATTGATGGATTCCTCCCCTTGACATATATATATACTTTGGGTTCCCGCAA...
     Positives=100%25
     Expect=3.5e-74,
     Identity=100%25
     Query_end=332
     Orientation=plus
     Score=1660
     Strand=Plus / Plus
     Subject_start=1
     Alignment=||||||||||||||||||||||||||||||||||||||||||||||||||||||||||...
   }
 }
 =

=head1 Example BLASTP run

Here is the output from a typical I<blastp> (protein->protein) run.
Long lines have again been truncated.

 Blast_run_date=Fri Nov  6 14:37:23 1998
 Blast_db_date=2:36 PM EST Nov 6, 1998
 Blast_parms={
   Hspmax=10
   Expectation=10
   Matrix=BLOSUM62
   Ctxfactor=1.00
 }
 Blast_program_date=05-Feb-1998
 Blast_db= /usr/tmp/quickblast18141aaaa
 Blast_version=2.0a19-WashU
 Blast_query=YAL004W
 Blast_db_title= elegans.fasta
 Blast_query_length=216
 Blast_program=blastp
 Blast_hits={
   Signif=0.95
   Expect=3.0,
   Name=C28H8.2
   Identity=30%25
   Length=51
   Hsps={
     Subject=HMTVEFHVTSQSW---FGFEDHFHMIIR-AVNDENVGWGVRYLSMAF
     Signif=0.95
     Length=46
     Bits=15.8
     Query_start=100
     Subject_end=49
     Query=HLTQD-HGGDLFWGKVLGFTLKFNLNLRLTVNIDQLEWEVLHVSLHF
     Positives=52%25
     Expect=3.0,
     Identity=30%25
     Query_end=145
     Orientation=plus
     Score=45
     Subject_start=7
     Alignment=H+T + H     W    GF   F++ +R  VN + + W V ++S+ F
   }
 }
 Blast_hits={
   Signif=0.99
   Expect=4.7,
   Name=ZK896.2
   Identity=24%25
   Length=340
   Hsps={
     Subject=FSGKFTTFVLNKDQATLRMSSAEKTAEWNTAFDSRRGFF----TSGNYGL...
     Signif=0.99
     Length=101
     Bits=22.9
     Query_start=110
     Subject_end=243
     Query=FWGKVLGFTL-KFNLNLRLTVNIDQLEWEVLHVSLHFWVVEVSTDQTLSVE...
     Positives=41%25
     Expect=4.7,
     Identity=24%25
     Query_end=210
     Orientation=plus
     Score=65
     Subject_start=146
     Alignment=F GK   F L K    LR++      EW     S   +     T     +...
   }
 }
 =

=cut

use strict;
use Stone;
use Boulder::Stream;
use Carp;
use vars qw($VERSION @ISA);
@ISA = 'Boulder::Stream';

*get        =  \&read_record;

$VERSION = 1.01;

sub new {
  my $self = shift;
  my $self = bless {},$self unless ref $self;
  $self->_open(@_);
  return $self;
}

# parse the contents of filehandle and emit a boulderio stream to stdout
sub parse {
  my $self = shift;
  $self = $self->new(shift) unless ref($self);
  $self->read_record();
}

sub _fh {
  my $self = shift;
  $self->{'fh'} = $_[0] if defined($_[0]);
  return $self->{'fh'};
}

sub read_record {
  my $self = shift;
  return if $self->done;
  my $fh = $self->_fh;
  my $stone = new Stone;
  local $/ = "\n"; # normalize input stream

  return unless my $line = <$fh>;
  croak "Doesn't look like a BLAST stream to me - top line = '$_'" unless $line=~/BLAST/;
  return unless my ($program,$version,$date) = $line=~ /^(\S+) (\S+) \[([^\]]+)\]/;
  my $stone = new Stone;

  $stone->insert ( Blast_version      => $version,
		   Blast_program      => lc $program,
		   Blast_program_date => $date );

  # the date isn't part of the file, so we use the creation date of the file
  # for this purpose.  If not available, then we are reading from a pipe
  # (maybe) and we use the current time.
  my $timestamp = -f $fh ? (stat(_))[9] : time;
  $stone->insert(Blast_run_date => scalar localtime($timestamp));

  if ($version =~ /WashU/) {
    require Boulder::Blast::WU;
    bless $self,'Boulder::Blast::WU';
  } else {
    require Boulder::Blast::NCBI;
    bless $self,'Boulder::Blast::NCBI';
  }

  $self->_read_record($fh,$stone);
}

sub _read_record {
  croak "unimplemented";
}

sub _open {
  my $self = shift;
  if (@_ > 1) {
    push @ARGV,@_;
    $self->_fh(\*ARGV);
    return;
  }
  my $fh = shift;
  unless (defined $fh) {
    # if $fh is null, then set it to ARGV
    $fh ||= \*ARGV;
  } elsif (!UNIVERSAL::isa($fh,'GLOB') && !UNIVERSAL::isa($fh,'FileHandle')) {
    # if $fh isn't a filehandle, then treat it as a filename to open
    croak "File does not exist" unless -e (my $name = $fh);
    $fh = Symbol::gensym;
    open($fh,$name) or croak "Can't open $name: $!\n";
  }
  $self->_fh($fh);
}

1;

