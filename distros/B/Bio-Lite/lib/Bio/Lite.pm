package Bio::Lite;
{
  $Bio::Lite::DIST = 'Bio-Lite';
}
# ABSTRACT: Lightweight and fast module with a simplified API to ease scripting in bioinformatics
$Bio::Lite::VERSION = '0.003';
use Carp;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(seqFileIterator reverseComplemente convertStrand pairedEndSeqFileIterator gffFileIterator getReadingFileHandle getWritingFileHandle);
our @EXPORT_OK = qw();


sub reverseComplemente {
  my $seq = reverse shift;
  $seq =~ tr/ACGTacgt/TGCAtgca/;
  return $seq;
}


my %conversion_hash = ( '+' => 1, '-' => '-1', '1' => '+', '-1' => '-');
sub convertStrand($) {
  my $strand = shift;
  return $conversion_hash{$strand};
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
      ($name) = <$fh> =~ /@(.*)$/;
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


sub gffFileIterator {
  my ($file,$format) = @_;

  croak "Missing arguments in gffFileIterator" if !defined $file || !defined $format;

  $format = lc $format;
  my $fh = getReadingFileHandle($file);

  my $attribute_split;

  if ($format eq 'gff3') {
    $attribute_split = sub {my $attr = shift; return $attr =~ /(\S+)=(.*)/;};
  } elsif ($format eq 'gtf' || $format eq 'gff2') {
    $attribute_split = sub {my $attr = shift; return $attr  =~ /(\S+)\s+"(.*)"/;};
  } else {
    croak "Undefined gff format";
  }

  my $line = <$fh>;
  while($line =~ /^#/) {
    $line = <$fh>;
  }

  return sub {
    if (defined $line) {
      my($chr,$source,$feature,$start,$end,$score,$strand,$frame,$attributes) = split("\t",$line);
      my @attributes_tab = split(";",$attributes);
      my %attributes_hash;
      foreach my $attr (@attributes_tab) {
        my ($k,$v) = $attribute_split->($attr);
        $attributes_hash{$k} = $v;
      }
      $line = <$fh>; # Get next line
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Lite - Lightweight and fast module with a simplified API to ease scripting in bioinformatics

=head1 VERSION

version 0.003

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
  my $it = pairedEndSeqFileIterator($file);
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

=head2 reverseComplemente

Reverse complemente the (nucleotid) sequence in arguement.

Example:

  my $seq_revcomp = reverseComplemente($seq);

reverseComplemente is more than B<100x faster than Bio-Perl> revcom_as_string()

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

  my $it = pairedEndSeqFileIterator($file);
  while (my $entry = $it->()) {
    print "Read_1 : $entry->{read1}->{seq}
           Read_2 : $entry->{read2}->{seq}";
  }

Return: HashRef

  { read1 => 'see seqFileIterator() return',
    read2 => 'see seqFileIterator() return'
  }

pairedEndSeqFileIterator has no equivalent in Bio-Perl

=head2 gffFileIterator 

manage GFF3 and GTF2 file format

Example:

  my $it = gffFileIterator($file);
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
    attributes  => { 'attribute_id' => 'attribute_value', ...}
  }

gffFileIterator is B<5x faster than Bio-Perl> Bio::Tools::GFF

=head1 FILES IO

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

=head1 TODO

=head1 AUTHOR

Jérôme Audoux <jaudoux@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jérôme Audoux.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
