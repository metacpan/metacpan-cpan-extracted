package CracTools::Utils;

{
  $CracTools::Utils::DIST = 'CracTools';
}
# ABSTRACT: A set of useful functions
$CracTools::Utils::VERSION = '1.251';
use strict;
use warnings;

use Carp;
use Fcntl qw( SEEK_SET );


sub reverseComplement($) {
  my $dna = shift;

  # reverse the DNA sequence
  my $revcomp = reverse $dna;

  # complement the reversed DNA sequence
  $revcomp =~ tr/ACGTacgt/TGCAtgca/;
  return $revcomp;
}


sub reverse_tab($) {
  my $string = shift;
  my @tab = split(/,/,$string);
  my $newString;
  if(@tab > 0) {
    for (my $i=$#tab ; $i > 0 ; $i--){
      $newString .= $tab[$i];
      $newString .= ",";
    }
    $newString .= $tab[0];
  }
  return $newString;
}


sub isVersionGreaterOrEqual($$) {
  my ($v1,$v2) = @_;
  my @v1_nums = split(/\./,$v1);
  my @v2_nums = split(/\./,$v2);
  for(my $i = 0; $i < @v1_nums; $i++) {
    if($v1_nums[$i] >= $v2_nums[$i]) {
      return 1;
    }else {
      return 0;
    }
  }
  if(scalar @v2_nums > @v1_nums) {
    return 0;
  } else {
    return 1;
  }
}


my %conversion_hash = ( '+' => 1, '-' => '-1', '1' => '+', '-1' => '-');
sub convertStrand($) {
  my $strand = shift;
  return defined $strand? $conversion_hash{$strand} : undef;
}

sub removeChrPrefix($) {
  my $string = shift;
  $string =~ s/^chr//i;
  return $string;
}

sub addChrPrefix($) {
  my $string = shift;
  return "chr".removeChrPrefix($string);
}


our $Base64_BITNESS = 6;
our @Base64_ENCODING = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 + /);

# Encode error list into base64
sub encodePosListToBase64 {
  my @pos_list = @_;
  my @bitList;
  my $encoded_str;

  return "" if @pos_list == 0;

  # Compute the appropriate length for the bitList
  my $length = $pos_list[-1] + 1;
  my $bitList_length = int($length / $Base64_BITNESS);
  if ($length % $Base64_BITNESS > 0) {
      $bitList_length++;
  }

  # Put 0 at all position
  for (my $i = 0; $i < $bitList_length; $i++) {
    $bitList[$i] = 0;
  }

  # Create bit vector in Base64_ENCODING
  foreach my $j (@pos_list) {
    $bitList[int($j / $Base64_BITNESS)] |= (1 << ($j % $Base64_BITNESS));
  }

  # Convert bitList into string_Base64_ENCODING
  for(my $k=0; $k < $bitList_length; $k++) {
    $encoded_str .= scalar($Base64_ENCODING[$bitList[$k]]);
  }
  return $encoded_str;
}


# Decode base 64 error list
sub decodePosListInBase64 {
  my $encoded_str = shift;

  my @encoded_list = split "", $encoded_str;
  my (@index,@decoded_list);

  #Looking for index of each char
  foreach my $j (@encoded_list) {
    my @ind = grep { $Base64_ENCODING[$_] eq $j } 0 .. $#Base64_ENCODING;
    push(@index,$ind[0]);
  }

  # Convert into list position
  for (my $e = 0; $e < (0+@encoded_list);$e++) {
    for(my $i=0; $i<$Base64_BITNESS; $i++) {
      if ($index[$e] & (1 << $i)) {
        my $pos = (int($i+$Base64_BITNESS*$e));
        push(@decoded_list,$pos);
      }
    }
  }

  return @decoded_list;
}




sub seqFileIterator {
  my ($file,$format) = @_;

  croak "Missing file in argument of seqFileIterator" if !defined $file;

  # Get file handle for $file
  my $fh = getReadingFileHandle($file);

  # Automatic file extension detection
  if(!defined $format) {
    if($file =~ /\.(fasta|fa)(\.|$)/) {
      $format = 'fasta';
    } elsif($file =~ /\.(fastq|fq)(\.|$)/) {
      $format = 'fastq';
    } else {
      croak "Undefined file extension";
    }
  } else {
    $format = lc $format;
  }

  # FASTA ITERATOR
  if ($format eq 'fasta') {
    # Read prev line for FASTA because we dont know the number
    # of line used for the sequence
    my $prev_line = <$fh>;
    chomp $prev_line;
    return sub {
      my ($name,$seq,$qual);
      if(defined $prev_line) {
        ($name) = $prev_line =~ />(.*)$/;
        $prev_line = <$fh>;
        # Until we find a new sequence identifier ">", we
        # concatenate the lines corresponding to the sequence
        while(defined $prev_line && $prev_line !~ /^>/) {
          chomp $prev_line;
          $seq .= $prev_line;
          $prev_line = <$fh>;
        }
        return {name => $name, seq => $seq, qual => $qual};
      } else {
        return undef;
      }
    };
  # FASTQ ITERATOR
  } elsif ($format eq 'fastq') {
    return sub {
      my ($name,$seq,$qual);
      my $line = <$fh>;
      ($name) = $line =~ /@(.*)$/ if defined $line;
      if(defined $name) {
        $seq = <$fh>;
        chomp $seq;
        <$fh>; # skip second seq name (useless line)
        $qual = <$fh>;
        chomp $qual;
        return {name => $name, seq => $seq, qual => $qual};
      } else {
        return undef;
      }
    };
  } else {
    croak "Undefined file format";
  }
}


sub pairedEndSeqFileIterator {
  my($file1,$file2,$format) = @_;

  my $it1 = seqFileIterator($file1,$format);
  my $it2 = seqFileIterator($file2,$format);

  return sub {
    my $entry1 = $it1->();
    my $entry2 = $it2->();
    if(defined $entry1 && defined $entry2) {
      return { read1 => $entry1, read2 => $entry2 };
    } else {
      return undef;
    }
  };
}


sub writeSeq {
  my ($fh,$format,$name,$seq,$qual) = @_;
  if($format eq 'fasta') {
    print $fh ">$name\n$seq\n";
  } elsif($format eq 'fastq') {
    print $fh '@'."$name\n$seq\n+\n$qual\n";
  } else {
    die "Unknown file format. Must be either a FASTA or a FASTQ";
  }
}


sub bedFileIterator {
  return getFileIterator(file => shift, type => 'bed');
}


sub gffFileIterator {
  my $file = shift;
  my $type = shift;
  return getFileIterator(file => $file, type => $type);
}


sub vcfFileIterator {
  my $file = shift;
  return getFileIterator(file => $file, type => 'vcf');
}


sub chimCTFileIterator {
  return getFileIterator(file => shift, type => 'chimCT');
}


sub bamFileIterator {
  my ($file,$region) = @_;
  $region = "" if !defined $region;

  my $fh;
  if($file =~ /\.bam$/) {
    open($fh, "-|", "samtools view $file $region" )or die "Cannot open $file, check if samtools are installed.";
  } else {
    $fh = getReadingFileHandle($file);
  }

  return sub {
    return <$fh>;
  }

}


sub getSeqFromIndexedRef {
  my ($ref_file,$chr,$pos,$length,$format) = @_;
  $format = 'fasta' if !defined $format;
  $pos++; # +1 because samtools faidx is 1-based
  # First we try without the "chr" prefix
  my $region = removeChrPrefix($chr).":$pos-".($pos+$length-1);
  my $fasta_seq = `samtools faidx $ref_file "$region"`;
  # If it has not worked, we try without
  if($fasta_seq !~ /^>\S+\n\S+/) {
    $region = addChrPrefix($chr).":$pos-".($pos+$length-1);
    $fasta_seq = `samtools faidx $ref_file "$region"`;
  }
  if($format eq 'raw') {
    my ($seq) = $fasta_seq =~ /^>\S+\n(\S+)/;
    return $seq;
  }
  return $fasta_seq;
}


sub parseBedLine {
  my $line = shift;
  my %args = @_;
  my($chr,$start,$end,$name,$score,$strand,$thick_start,$thick_end,$rgb,$block_count,$block_size,$block_starts) = split("\t",$line);
  my @blocks;

  # Manage blocks if we have a bed12
  if(defined $block_starts) {
    my @block_size = split(",",$block_size);
    my @block_starts = split(",",$block_starts);
    my $cumulated_block_size = 0;
    for(my $i = 0; $i < $block_count; $i++) {
      push(@blocks,{size        => $block_size[$i],
                   start        => $block_starts[$i],
                   end          => $block_starts[$i] + $block_size[$i],
                   block_start  => $cumulated_block_size,
                   block_end    => $cumulated_block_size + $block_size[$i],
                   ref_start    => $block_starts[$i] + $start,
                   ref_end      => $block_starts[$i] + $start + $block_size[$i],
                 });
      $cumulated_block_size += $block_size[$i];
    }
  }

  return { chr        => $chr,
    start       => $start,
    end         => $end,
    name        => $name,
    score       => $score,
    strand      => $strand,
    thick_start => $thick_start,
    thick_end   => $thick_end,
    rgb         => $rgb,
    blocks      => \@blocks,
  };
}


sub parseGFFLine {
  my $line = shift;
  my $type = shift;
  my $attribute_split;
  if($type =~ /gff3/i) {
    $attribute_split = sub {my $attr = shift; return $attr =~ /(\S+)=(.*)/;};
  } elsif ($type eq 'gtf' || $type eq 'gff2') {
    $attribute_split = sub {my $attr = shift; return $attr  =~ /(\S+)\s+"?(.*)"?/;};
  } else {
    croak "Undefined GFF format (must be either gff3,gtf, or gff2)";
  }
  my($chr,$source,$feature,$start,$end,$score,$strand,$frame,$attributes) = split("\t",$line);
  my @attributes_tab = split(";",$attributes);
  my %attributes_hash;
  foreach my $attr (@attributes_tab) {
    my ($k,$v) = $attribute_split->($attr);
    if(defined $k and defined $v) {
      $attributes_hash{$k} = $v;
    }
  }
  return { chr        => $chr,
    source     => $source,
    feature    => $feature,
    start      => $start,
    end        => $end,
    score      => $score,
    strand     => $strand,
    frame      => $frame,
    attributes => \%attributes_hash,
  };
}


sub parseVCFLine {
  my $line = shift;
  my($chr,$pos,$id,$ref,$alt,$qual,$filter,$info) = split("\t",$line);

  my @alts = defined $alt? split(",",$alt) : ();
  my %infos = defined $info?
  map { my ($k,$v) = split '='; $k => $v } split ';', $info : ();

  return { chr => $chr,
    pos     => $pos,
    id      => $id,
    ref     => $ref,
    alt     => \@alts,
    qual    => $qual,
    filter  => $filter,
    info    => \%infos,
  };
}


sub parseChimCTLine {
  my $line = shift;
  my($id,$name,$chr1,$pos1,$strand1,$chr2,$pos2,$strand2,$chim_value,$spanning_junction,$spanning_PE,$class,$comments,@others) = split("\t",$line);
  my($sample,$chim_key) = split(":",$id);
  my @comments = split(",",$comments);
  my %comments;
  foreach my $com (@comments){
      my ($key,$val) = split("=",$com);
      $comments{$key} = $val;
  }
  my %extend_fields;
  foreach my $field (@others) {
    my ($key,$val) = split("=",$field);
    if(defined $key && defined $val) {
      $extend_fields{$key} = $val;
    }
  }
  return {
    sample            => $sample,
    chim_key          => $chim_key,
    name              => $name,
    chr1              => $chr1,
    pos1              => $pos1,
    strand1           => $strand1,
    chr2              => $chr2,
    pos2              => $pos2,
    strand2           => $strand2,
    chim_value        => $chim_value,
    spanning_junction => $spanning_junction,
    spanning_PE       => $spanning_PE,
    class             => $class,
    comments          => \%comments,
    extended_fields     => \%extend_fields,
  };
}


sub parseSAMLineLite {
  my $line = shift;
  my ($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnext,$tlen,$seq,$qual,@others) = split("\t",$line);
  my @cigar_hash = map { { op => substr($_,-1), nb => substr($_,0,length($_)-1)} } $cigar =~ /(\d+\D)/g;
  return {
    qname => $qname,
    flag => $flag,
    rname => $rname,
    pos => $pos,
    mapq => $mapq,
    cigar => \@cigar_hash,
    original_cigar => $cigar,
    rnext => $rnext,
    pnext => $pnext,
    tlen => $tlen,
    seq => $seq,
    qual => $qual,
    extended_fields => \@others,
  };
}


sub parseCigarChain {
  my $cigar_string = shift;
  my @cigar;
  while($cigar_string =~ /(\d+)(\S)/g) {
    push @cigar, { op => $2, nb => $1 };
  }
  return \@cigar;
}



sub getFileIterator {
  my %args = @_;
  my $file = $args{file};
  my $type = $args{type};
  my $skip = $args{skip};
  my $header_regex = $args{header_regex};
  my $parsing_method = $args{parsing_method};
  my @parsing_arguments = ();


  croak "Missing arguments in getFileIterator" if !defined $file;

  if(!defined $parsing_method && defined $type) {
    if($type =~ /gff3/i || $type eq 'gtf' || $type eq 'gff2') {
      $header_regex = '^#';
      $parsing_method = sub { return parseGFFLine(@_,$type) };
      push (@parsing_arguments,$type);
    } elsif($type =~ /bed/i) {
      $header_regex = '(^track\s)|(^#)';
      $parsing_method = \&parseBedLine;
    } elsif ($type =~ /vcf/i) {
      $header_regex = '^#';
      $parsing_method = \&parseVCFLine;
    } elsif ($type =~ /chimCT/i) {
      $header_regex = '^#';
      $parsing_method = \&parseChimCTLine;
    } elsif ($type =~ /SAM/i || $type =~ /BAM/i) {
      $header_regex = '^@';
      $parsing_method = \&parseSAMLineLite;
    } else {
      croak "Undefined format type";
    }
  }

  # set defaults
  #$header_regex = '^#' if !defined $header_regex;
  $parsing_method = sub{ return { line => shift } } if !defined $parsing_method;

  # We get a filehandle on the file
  my $fh = getReadingFileHandle($file);

  # $curr_pos will hold the SEEK_POS of the current_line
  my $curr_pos = tell($fh);
  # $line will hold the content of the current_line
  my $line = <$fh>;


  # if we need to skip lines
  if(defined $skip) {
    for(my $i = 0; $i < $skip; $i++) {
      $curr_pos = tell($fh);
      $line = <$fh>;
    }
  }

  # Skip line that match a specific regex
  if(defined $header_regex) {
    while($line && $line =~ /$header_regex/) {
      $curr_pos = tell($fh);
      $line = <$fh>;
    }
  }

  # The iterator itself (an unnamed subroutine
  return sub {
    if (defined $line) {
      chomp $line;
      # We parse the line with the appropriate methd
      my $parsed_line = $parsing_method->($line,@parsing_arguments);
      # Add seek pos to the output hashref
      $parsed_line->{seek_pos} = $curr_pos;
      $parsed_line->{_original_line} = $line;
      $curr_pos = tell($fh);
      $line = <$fh>; # Get next line
      return $parsed_line;
    } else {
      return undef;
    }
  };
}


sub getReadingFileHandle {
  my $file = shift;
  my $fh;
  if($file =~ /\.gz$/) {
    open($fh,"gunzip -c $file |") or die ("Cannot open $file");
  } else {
    open($fh,"< $file") or die ("Cannot open $file");
  }
  return $fh;
}


sub getWritingFileHandle {
  my $file = shift;
  my $fh;
  if($file =~ /\.gz$/) {
    open($fh,"| gzip > $file") or die ("Cannot open $file");
  } else {
    open($fh,"> $file") or die ("Cannot open $file");
  }
  return $fh;
}


sub getLineFromSeekPos {
  my($fh,$seek_pos) = @_;
  seek($fh,$seek_pos,SEEK_SET);
  my $line = <$fh>;
  chomp($line);
  return $line;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Utils - A set of useful functions

=head1 VERSION

version 1.251

=head1 SYNOPSIS

  # Reverse complementing a sequence
  my $seq = reverseComplemente("ATGC");

  # Reading a FASTQ file
  my $it = seqFileIterator('file.fastq','fastq');
  while(my $entry = $it->()) {
    print "Sequence name   : $entry->{name}
           Sequence        : $entry->{seq}
           Sequence quality: $entry->{qual}","\n";
  }

  # Reading paired-end files easier
  my $it = pairedEndSeqFileIterator($reads1,$reads2,$format);
  while (my $entry = $it->()) {
    print "Read_1 : $entry->{read1}->{seq}
           Read_2 : $entry->{read2}->{seq}";
  }

  # Parsing a GFF file
  my $it = gffFileIterator($file);
  while (my $annot = $it->()) {
    print "chr    : $annot->{chr}
           start  : $annot->{start}
           end    : $annot->{end}";
  }

=head1 DESCRIPTION

Bio::Lite is a set of subroutines that aims to answer similar questions as
Bio-perl distribution in a FAST and SIMPLE way.

Bio::Lite does not make use of complexe data struture, or
objects, that would lead to a slow execution.

All methods can be imported with a single "use Bio::Lite".

Bio::Lite is a lightweight-single-module with NO DEPENDENCIES.

=head1 UTILS

=head2 reverseComplement

Reverse complemente the (nucleotid) sequence in arguement.

Example:

  my $seq_revcomp = reverseComplement($seq);

reverseComplement is more than B<100x faster than Bio-Perl> revcom_as_string()

=head2 reverse_tab

  Arg [1] : String - a string with values separated with coma.
  Example : $reverse = reverse_tab('2,1,1,1,0,0,1');
  Description : Reverse the values of the string in argument.
                For example : reverse_tab('1,2,0,1') returns : '1,0,2,1'.
  ReturnType  : String
  Exceptions  : none

=head2 isVersionGreaterOrEqual($v1,$v2)

Return true is version number v1 is greater than v2

=head2 convertStrand

Convert strand from '+/-' standard to '1/-1' standard and the opposite.

Example:

  say "Forward a: ",convertStrand('+');
  say "Forward b: ",convertStrand(1);
  say "Reverse a: ",convertStrand('-');
  say "Reverss b: ",convertStrand(-1);

will print

  Forward a: 1
  Forward b: +
  Reverse a: -1
  Reverse b: -

=head2 removeChrPrefix

Remove the "chr" prefix from a given string

Example:

  say "reference name: ",removeChrPrefix("chr1");

will print

  reference name: 1

=head2 addChrPrefix

Add the "chr" prefix to the given string

=head1 ENCODING

=head2 encodePosListToBase64

Encode a (0-based) list of increasing position to a string using Base64
encoding scheme : ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/

  my $encoded_list = CracTools::Utils::encodePosListToBase64(1,3,5,8,12,32);
  my @decoded_list = CracTools::Utils::decodePosListInBase64($encoded_list);

=head2 decodePosListInBase64

Decode position list encoded by encodePosListToBase64.

=head1 PARSING

This are some tools that aim to read (bio) files like

=over

=item Sequence files : FASTA, FASTQ

=item Annotation files : GFF3, GTF2, BED6, BED12, ...

=item Alignement files : SAM, BAM

=back

=head2 seqFileIterator

Open Fasta, or Fastq files (can be gziped).
seqFileIterator has an automatic file extension detection but you can force it
using a second parameter with the format : 'fasta' or 'fastq'.

Example:

  my $it = seqFileIterator('file.fastq','fastq');
  while(my $entry = $it->()) {
    print "Sequence name   : $entry->{name}
           Sequence        : $entry->{seq}
           Sequence quality: $entry->{qual}","\n";
  }

Return: HashRef

  { name => 'sequence_identifier',
    seq  => 'sequence_value',
    qual => 'sequence_quality', # only defined for FASTQ files
  }

seqFileIterator is more than B<50x faster than Bio-Perl> Bio::SeqIO for FASTQ files
seqFileIterator is 4x faster than Bio-Perl Bio::SeqIO for FASTA files

=head2 pairedEndSeqFileIterator

Open Paired-End Sequence files using seqFileIterator()

Paird-End files are generated by Next Generation Sequencing technologies (like Illumina) where two
reads are sequenced from the same DNA fragment and saved in separated files.

Example:

  my $it = pairedEndSeqFileIterator($reads1,$reads2,$format);
  while (my $entry = $it->()) {
    print "Read_1 : $entry->{read1}->{seq}
           Read_2 : $entry->{read2}->{seq}";
  }

Return: HashRef

  { read1 => 'see seqFileIterator() return',
    read2 => 'see seqFileIterator() return'
  }

pairedEndSeqFileIterator has no equivalent in Bio-Perl

=head2 writeSeq

  CracTools::Utils::writeSeq($filehandle,$format,$seq_name,$seq,$seq_qual)

Write the sequence in the output stream with the specified format.

=head2 bedFileIterator

manage BED files format

Example:

  my $it = bedFileIterator($file);
  while (my $annot = $it->()) {
    print "chr    : $annot->{chr}
           start  : $annot->{start}
           end    : $annot->{end}";
  }

Return a hashref with the annotation parsed:

  { chr         => 'field_1',
    start       => 'field_2',
    end         => 'field_3',
    name        => 'field_4',
    score       => 'field_5',
    strand      => 'field_6',
    thick_start => 'field_7',
    thick_end   => 'field_8',
    rgb         => 'field_9'
    blocks      => [ {'size' => 'block size',
                      'start' => 'block start',
                      'end'   => 'block start + block_size',
                      'ref_start' => 'block start on the reference',
                      'ref_end'   => 'block end on the reference'}, ... ],
    seek_pos    => 'Seek position of this line in the file',
  }

=head2 gffFileIterator

manage GFF3 and GTF2 file format

Example:

  my $it = gffFileIterator($file,'type');
  while (my $annot = $it->()) {
    print "chr    : $annot->{chr}
           start  : $annot->{start}
           end    : $annot->{end}";
  }

Return a hashref with the annotation parsed:

  { chr         => 'field_1',
    source      => 'field_2',
    feature     => 'field_3',
    start       => 'field_4',
    end         => 'field_5',
    score       => 'field_6',
    strand      => 'field_7',
    frame       => 'field_8'
    attributes  => { 'attribute_id' => 'attribute_value', ...},
    seek_pos    => 'Seek position of this line in the file',
  }

gffFileIterator is B<5x faster than Bio-Perl> Bio::Tools::GFF

=head2 vcfFileIterator

manage VCF file format

Return a hashref with the annotation parsed:

  { chr => $chr,
    pos     => $pos,
    id      => $id,
    ref     => $ref,
    alt     => [ alt1, alt2, ...],
    qual    => $qual,
    filter  => $filter,
    info    => { AS => value,
                 DP => value,
                 ...
                 ,
  };

=head2 chimCTFileIterator

Return a hashref with the chimera parsed:

  {
    sample            => $sample,
    chim_key          => $chim_key,
    name              => $name,
    chr1              => $chr1,
    pos1              => $pos1,
    strand1           => $strand1,
    chr2              => $chr2,
    pos2              => $pos2,
    strand2           => $strand2,
    chim_value        => $chim_value,
    spanning_junction => $spanning_junction,
    spanning_PE       => $spanning_PE,
    class             => $class,
    comments          => { coment_id => 'comment_value', ... },
    extended_fields     => { extended_field_id => 'extended_field_value', ... },
  }

=head2 bamFileIterator

BE AWARE this method is only availble if C<samtools> binary is availble.

Return an iterator over a BAM file using a C<samtools view> pipe.

A region can be passed in parameter to restrict the results. In this case
the BAM file must be indexed

Example:

  my $fh = bamFileIterator("file.bam","17:43,971,748-44,105,700");
  while(my $line = <$fh>) {
    my $parsed_line = CracTools::SAMReader::SAMline->new($line);
    // do some stuff
  }

SEE ALSO CracTools::SAMReader::SAMline if you need to parse SAMlines easily

=head2 getSeqFromIndexedRef

BE AWARE this method is only availble if C<samtools> binary is availble.

Return a sequence from a given region in a fasta indexed file

Example:

  my $fasta_seq = getSeqFromIndexedRef("file.fa","chr2",29012,10);
  my $seq       = getSeqFromIndexedRef("file.fa","chr2",29012,10,'raw');

=head1 PARSING LINES

=head2 parseBedLine

=head2 parseGFFLine

=head2 parseVCFLine

=head2 parseChimCTLine

=head2 parseSAMLineLite

=head2 parseCigarChain

Given a CIGAR chain (see SAM specification), return a parsed version as an Array ref of
cigar elements represented as { nb => 10, op => 'M' }.

=head1 FILES IO

=head2 getFileIterator

Generic method to parse files.

=head2 getReadingFileHandle

Return a file handle for the file in argument.
Display errors if file cannot be oppenned and manage gzipped files (based on .gz file extension)

Example:

  my $fh = getReadingFileHandle('file.txt.gz');
  while(<$fh>) {
    print $_;
  }
  close $fh;

=head2 getWritingFileHandle

Return a file handle for the file in argument.
Display errors if file cannot be oppenned and manage gzipped files (based on .gz file extension)

Example:

  my $fh = getWritingFileHandle('file.txt.gz');
  print $fh "Hello world\n";
  close $fh;

=head2 getLineFromSeekPos

  getLineFromSeekPos($filehandle,$seek_pos);

return a chomped line at a seeking position.

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
