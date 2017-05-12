package Bio::FASTASequence;

# ABSTRACT: Parsing sequence informations in FASTA format.

use 5.006;
use strict;
use warnings;

our $VERSION = '0.07';

#
# new creates a new instance of Bio::FASTASequence
#
sub new{
  my ($class, $string_text) = @_;
  my ($description,$accession_nr);
  my %f_db_nr = ();
  unless($string_text){
    $string_text = "";
  }
  my $self = {};
  bless($self,$class);
  my $sequencer;
  #print STDERR "Object doesn't contain fasta-sequence" if($string_text && !_is_fasta($string_text));
  die "Object doesn't contain fasta-sequence" if($string_text && !_is_fasta($string_text));
  if($string_text){
    $string_text =~ s/^(\r?\n)+//;
    $string_text =~ s/^>+/>/;
    my ($description_line,$sequence) = split(/\n/,$string_text,2);
    $description_line =~ s/\s+$//;
    $description_line =~ s/\r?\n/\n/g;
    $sequence =~ s/\r?\n//g;
    unless($description_line =~ /^>/){
      $self->{accession_nr} = "";
    }
    else{
      # parsing the description line
      if($description_line =~ /^>gi\|/){
        my ($gi,$number,$db);
        $description_line =~ s/^>//;
        ($gi,$number,$db,$accession_nr,$description) = split(/\|/,$description_line);
      }
      elsif($description_line =~ /^>sp\|/ || $description_line =~ /^>sptrembl\|/){
        $description_line =~ s/^>//;
        my $desc;
        ($desc,$description) = split(/\s/,$description_line,2);
        $accession_nr = (split(/\|/,$desc))[1];
      }
      elsif($description_line =~ /^>tr\|/){
        $description_line =~ s/^>//;
        my $desc;
        ($desc,$description) = split(/\s/,$description_line,2);
        $accession_nr = (split(/\|/,$desc))[1];
      }
      elsif($description_line =~ /^>[XY\d+]/){
        $description_line =~ s/>//;
        chomp $description_line;
        $description = (split(/\s/,$description_line,3))[-1];
        $accession_nr = (split(/\s/,$description_line,3))[0];
      }
      elsif($description_line =~ /^>[0-9A-Za-z_]+\s?/){
        $description_line =~ s/^>//;
        #-------------------------------------------------#
        # IPI-Sequences                                   #
        #-------------------------------------------------#
        if($description_line =~ /^IPI:/){
          # split only at first whitespace and take first element
          my $foreign_numbers = (split(/\s/,$description_line,2))[0];
          $description = (split(/\s/,$description_line,3))[2];
          my @foreign_acs = split(/\|/,$foreign_numbers);
          # cross-references to other databases
          foreach my $f_ac(@foreign_acs){
            my ($key, $value) = split(/:/,$f_ac);
            $f_db_nr{$key} = $value;
          }
          unless($f_db_nr{'SWISS-PROT'}){
            $f_db_nr{'SWISS-PROT'} = "NULL";
          }
          unless($f_db_nr{'ENSEMBL'}){
            $f_db_nr{'ENSEMBL'} = "NULL";
          }
          unless($f_db_nr{'REFSEQ_XP'}){
            $f_db_nr{'REFSEQ_XP'} = "NULL";
          }
          unless($f_db_nr{'TREMBL'}){
            $f_db_nr{'TREMBL'} = "NULL";
          }
          $accession_nr = $f_db_nr{'IPI'};
          delete $f_db_nr{IPI};
        }
        #-----------------------------------------#
        # format begins with accession-nr         #
        #-----------------------------------------#
        elsif($description_line =~ /^[A-Za-z][0-9][A-Z0-9a-z]{3}[0-9][\s\|]/){
          if($description_line =~ /\|/){
            ($accession_nr, $description) = split(/\|/,$description_line,2);
          }
          else{
            ($accession_nr, $description) = split(/\s/,$description_line,2);
	  }
        }
        elsif($description_line =~ /^[A-Za-z0-9_]+\s*?$/){
          chomp $description_line;
          $accession_nr = $description_line;
          $description_line = '';
        }
        else{
          ($accession_nr,$description)= split(/\s/,$description_line,2);
        }
      }
    }

    $accession_nr =~ s/^>//;
    $accession_nr =~ s/[^\w\d]*?$//;
    $accession_nr =~ s/\.\d$//;
    $sequence =~ s/[^A-Z]//g;
    $sequencer = $sequence;
  }

  $self->{text}         = $sequencer;
  $self->{accession_nr} = $accession_nr;
  $self->{description}  = $description;
  $self->{seq_length}   = length($sequencer);
  $self->{dbrefs}       = \%f_db_nr;
  $self->{crc64}        = $self->_crc64();

  return $self;
}#end new

#
# getSequence returns the sequence itself.
#
sub getSequence{
  my ($class) = @_;
  return $class->{text};
}# end getText

#
# _is_fasta checks whether the given Sequence is in fasta-format or not
#
sub _is_fasta{
  my ($sequence) = @_;
  my @lines      = split(/\r?\n/,$sequence);
  my $desc       = shift(@lines);
  my $seq        = join("",@lines);
  $seq =~ s/\s+//g;
  if($desc =~ /^>/ && $seq !~ /[^A-NP-Z\*\-]/i && length($seq) > 0){
    return 1;
  }
  return 0;
}# end _is_fasta

#
# getSequenceLength returns how man aminoacids the sequence contains
#
sub getSequenceLength{
  my ($class) = @_;
  return $class->{seq_length};
}# end getSequenceLength

# 
# getAccessionNr returns the parsed accession number
#
sub getAccessionNr{
  my ($class) = @_;
  return $class->{accession_nr};
}# end of getAccessionNr

#
# getDescription returns the description
#
sub getDescription{
  my ($class) = @_;
  return $class->{description}
}# end getDescription

#
# getCrc64 returns the crc64-checksum of the sequence
#
sub getCrc64{
  my ($class) = @_;
  return $class->{crc64};
}# end getCrc64

# 
# getDBRefs returns an anonymous hash containing all references to foreign databases
#
sub getDBRefs{
  my ($class) = @_;
  return $class->{dbrefs};
}# end getDBRefs

#
# allIndexesOf returns a reference to an array containing all positions of the requested Substring
#
sub allIndexesOf{
  my ($self,$search) = @_;
  my $i = 1;
  my $index = 0;
  my @indices = ();
  while($i != -1){
    $index = index($self->{text},$search,$index);
    push(@indices,$index) unless ($index == -1);
    $i = $index;
    $index++;
  }
  return \@indices;
}# end allIndicesOf

#
# _crc64 calculates the crc64-checksum of the sequence. It's the crc64-checksum like at swiss-prot
# the code is mainly adapted from SWISS::CRC64
#
sub _crc64 {
  my ($self)     = @_;
  my $text = $self->{text};
  use constant EXP => 0xd8000000;
  my @highCrcTable = 256;
  my @lowCrcTable  = 256;
  my $initialized  = ();
  my $low          = 0;
  my $high         = 0;

  unless($initialized) {
    $initialized = 1;
    for my $i(0..255) {
      my $low_part  = $i;
      my $high_part = 0;
      for my $j(0..7) {
        my $flag = $low_part & 1; # rflag ist für alle ungeraden zahlen 1
        $low_part >>= 1;# um ein bit nach rechts verschieben
        $low_part |= (1 << 31) if $high_part & 1; # bitweises oder mit 2147483648 (), wenn $parth ungerade
        $high_part >>= 1; # um ein bit nach rechtsverschieben
        $high_part ^= EXP if $flag;
      }
      $highCrcTable[$i] = $high_part;
      $lowCrcTable[$i]  = $low_part;
    }
  }

  foreach (split '', $text) {
    my $shr = ($high & 0xFF) << 24;
    my $tmph = $high >> 8;
    my $tmpl = ($low >> 8) | $shr;
    my $index = ($low ^ (unpack "C", $_)) & 0xFF;
    $high = $tmph ^ $highCrcTable[$index];
    $low  = $tmpl ^ $lowCrcTable[$index];
  }
  return sprintf("%08X%08X", $high, $low);
}# end crc64

#
# seq2file prints the sequence into a file in fasta-file
#
sub seq2file{
  my ($self,$file,$args_ref) = @_;
  # open the file to write
  open(W_SEQUENCE,">$file") or die "Can't open $file: $!\n";
  print W_SEQUENCE ">",$self->{accession_nr};
  # add the references
  foreach my $dbkey(keys(%{$self->{dbrefs}})){
    print W_SEQUENCE "|".$dbkey.":".$self->{dbrefs}->{$dbkey} if($self->{dbrefs}->{$dbkey} ne 'NULL');
  }
  # add description
  print W_SEQUENCE " ",$self->{description},"\n";
  # add the sequence
  print W_SEQUENCE $self->{text},"\n";
  close W_SEQUENCE;
}# end seq2file

#
# getFASTA return a string in fasta-format
#
sub getFASTA{
  my ($self)     = @_;
  my $fasta = ">".$self->{accession_nr};
  # add the references to foreign databases
  foreach my $dbkey(keys(%{$self->{dbrefs}})){
    $fasta .= "|".$dbkey.":".$self->{dbrefs}->{$dbkey} if($self->{dbrefs}->{$dbkey} ne "NULL");
  }
  # add description
  $fasta .= " ".$self->{description} if($self->{description});
  $fasta .= "\n";
  # add sequence
  $fasta .= $self->{text}."\n";
  return $fasta;
}# end getFASTA

#
# addDBRef adds a reference to a foreign database to the anonymous hash
#
sub addDBRef{
  my ($self,$db,$dbref) = @_;
  # if a reference to the requested database already exists, append the new reference
  if($self->{dbrefs}->{$db} && ($self->{dbrefs}->{$db} ne 'NULL')){
    $self->{dbrefs}->{$db} .= ";".$dbref;
  }
  # if no reference exists, add the reference to the hash
  else{
    $self->{dbrefs}->{$db} = $dbref;
  }
}# end addDBRef

#
# seq2xml creates an xml-string containing all information about the given sequence.
#
sub seq2xml{
  my ($self) = @_;
  # create the tags representing the references to foreign databases, e.g. SWISS-Prot
  my $dbrefs = " ";
  foreach(keys(%{$self->{dbrefs}})){
    my $key     = uc($_);
    $dbrefs .= "\n<".$key.'>'.${$self->{dbrefs}}->{$_}.'</'.$key.'>' if(${$self->{dbrefs}}->{$_} ne 'NULL');
  }
  $dbrefs    = "\n<DBREFS>$dbrefs</DBREFS>" if($dbrefs ne " ");
  # create the xml-string
  my $xml = qq~
  <SEQUENCE id="$self->{accession_nr}">
    <DESCRIPTION>$self->{description}</DESCRIPTION>$dbrefs
    <LENGTH>$self->{seq_length}</LENGTH>
    <CRC64>$self->{crc64}</CRC64>
    <TEXT>$self->{text}</TEXT>
  </SEQUENCE>~;
  return $xml;
}# end seq2xml

1;

__END__

=pod

=head1 NAME

Bio::FASTASequence - Parsing sequence informations in FASTA format.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Bio::FASTASequence;
  my $fasta = qq~>sp|P01815|HV2B_HUMAN Ig heavy chain V-II region COR - Homo sapiens (Human).
QVTLRESGPALVKPTQTLTLTCTFSGFSLSSTGMCVGWIRQPPGKGLEWLARIDWDDDKY
YNTSLETRLTISKDTSRNQVVLTMDPVDTATYYCARITVIPAPAGYMDVWGRGTPVTVSS
  ~;
  my $seq = Bio::FASTASequence->new($fasta);

=head1 DESCRIPTION

This perl module is a simple utility to simplify the job of bioinformatics.
It parses several information about a given FASTA-Sequence such as:

=over 10

=item * accession number

=item * description

=item * sequence itself

=item * length of sequence

=item * crc64 checksum (as it is used by SWISS-PROT)

=item * seq2xml

=back

=head2 METHODS

=head3 new

=head3 getAccessionNr

	my $accession = $seq->getAccessionNr();

returns the AccessionNr of the FASTA-Sequence

=head3 getDescription

	my $description = $seq->getDescription();

returns the description standing in the first line of the
FASTA-format (without the accession number)

=head3 getSequence

	my $sequence = $seq->getSequence();

returns the sequence

=head3 getCrc64

	my $crc64_checksum = $seq->getCrc64();

returns the crc64 checksum of the sequence. This checksum
corresponds with the crc64 checksum of SWISS-PROT

=head3 addDBRef

	$seq->addDBRef(DB, REFERENCE_AC);

DB is the name of the referenced database

REFERENCE_AC is the accession number in the referenced database

=head3 seq2file

	$seq->seq2file(FILENAME);

FILENAME is the path of the file where the sequence has to be stored.

=head3 allIndexesOf

	my $indexes = $seq->allIndexesOf(EXPR);

returns a reference on an array, which contains all indexes of
EXPR in the sequence

=head3 getSequenceLength

	my $length = $seq->getSequenceLength();

returns the length of the sequence

=head3 getDBRefs

	my $hashref = $seq->getDBRefs();

returns a hashreference. The hash contains all references
	hashref = {'SWISS-PROT' => 'P01815'},

=head3 getFASTA

	my $fasta_sequence = $seq->getFASTA();

returns the sequence in FASTA-format

=head2 EXAMPLE

	use Bio::FASTASequence;
	my $fasta = qq~>sp|P01815|HV2B_HUMAN Ig heavy chain V-II region COR - Homo sapiens (Human).
	QVTLRESGPALVKPTQTLTLTCTFSGFSLSSTGMCVGWIRQPPGKGLEWLARIDWDDDKY
	YNTSLETRLTISKDTSRNQVVLTMDPVDTATYYCARITVIPAPAGYMDVWGRGTPVTVSS
	~;

	my $seq = Bio::FASTASequence->new($fasta);

	print 'The sequence of '.$seq->getAccessionNr().' is '.$seq->getSequence(),"\n";
	print 'This sequence contains '.scalar($seq->allIndexesOf('C').' times Cystein at the following positions:';
	print $_+1.', ' for(@{$seq->allIndexesOf('C')});

=head1 ABSTRACT

  Bio::FASTASequence is a perl module to parse information out off a Fasta-Sequence.

=head1 ADDITIONAL INFORMATION

=head3 accepted formats

This module can parse the following formats:

=over 4

=item >P02656 APC3_HUMAN Apolipoprotein C-III precursor (Apo-CIII).

=item >IPI:IPI00166553|REFSEQ_XP:XP_290586|ENSEMBL:ENSP00000331094|TREMBL:Q8N3H0 T Hypothetical protein

=item >sp|P01815|HV2B_HUMAN Ig heavy chain V-II region COR - Homo sapiens (Human).

=back

=head3 structure

The structure of the hash for the example is:

	$VAR1 = {
	         'seq_length' => 120,
	         'accession_nr' => 'P01815',
	         'text' => 'QVTLRESGPALVKPTQTLTLTCTFSGFSLSSTGMCVGWIRQPPGKGLEWLARIDWDDDKYYNTSLETRLTISKDTSRNQVVLTMDPVDTATYYCARITVIPAPAGYMDVWGRGTPVTVSS',
	         'crc64' => '158A8B29AE7EEB98',
	         'dbrefs' => {},
	         'description' => 'Ig heavy chain V-II region COR - Homo sapiens (Human).'
	       }

if you miss something please contact me.

=head1 BUGS

There is no bug known. If you experienced any problems, please contact me.

=head1 SEE ALSO

http://modules.renee-baecker.de # not available yet - this site is under construction

the crc64-routine is based on the
SWISS::CRC64
module.

=head1 MODIFICATIONS

More FASTA-Description lines are accepted.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
