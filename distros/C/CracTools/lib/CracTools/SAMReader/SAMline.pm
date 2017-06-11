package CracTools::SAMReader::SAMline;

{
  $CracTools::SAMReader::SAMline::DIST = 'CracTools';
}
# ABSTRACT: The object for manipulation a SAM line.
$CracTools::SAMReader::SAMline::VERSION = '1.251';

use strict;
use warnings;
use Carp;

use CracTools::Utils;


our %flags = ( MULTIPLE_SEGMENTS => 1,
            PROPERLY_ALIGNED => 2,
            UNMAPPED => 4,
            NEXT_UNMAPPED => 8,
            REVERSE_COMPLEMENTED => 16,
            NEXT_REVERSE_COMPLEMENTED => 32,
            FIRST_SEGMENT => 64,
            LAST_SEGMENT => 128,
            SECONDARY_ALIGNMENT => 256,
            QUALITY_CONTROLS_FAILED => 512,
            PCR_DUPLICATED => 1024,
            CHIMERIC_ALIGNMENT => 2048,
          );



sub hasEvent {
  my ($line,$event_type) = @_;
  croak("Missing argument(s)") unless defined $line && defined $event_type;
  return $line =~ /XE:Z:\d+:\d+:$event_type/i;
}


sub new {
  my $class = shift;
  my ($line) = @_;
  chomp $line;  
  my ($qname,$flag,$rname,$pos,$mapq,$cigar,$rnext,$pnext,$tlen,$seq,$qual,@others) = split("\t",$line);
  my %extended_fields;
  foreach(@others) {
    my $key = substr($_,0,2);
    my $value = substr($_,5);
    #my($key,$type,$value) = split(':',$_,3); 
    # Hack in case there is multiple field with the same tag
    $extended_fields{$key} = defined $extended_fields{$key}? $extended_fields{$key}.";".$value : $value;
  }
  
  # We do not want any "chr" string before the reference sequence value
  $rname =~ s/^chr//;

  my $self = bless{ 
    qname => $qname,
    flag => $flag,
    rname => $rname,
    pos => $pos,
    mapq => $mapq,
    cigar => $cigar,
    rnext => $rnext,
    pnext => $pnext,
    tlen => $tlen,
    seq => $seq,
    qual => $qual,
    extended_fields => \%extended_fields,
    line => $line,
  }, $class;

  return $self;
}


sub isFlagged {
  my $self = shift;
  my $flag = shift;
  return $self->flag & $flag;
}


sub getStrand {
  my $self = shift;
  if($self->isFlagged($flags{REVERSE_COMPLEMENTED})) {
    return -1;
  } else {
    return 1;
  }
}


sub getOriginalSeq {
  my $self = shift;
  if($self->isFlagged($flags{REVERSE_COMPLEMENTED})) {
    return CracTools::Utils::reverseComplement($self->seq);
  } else {
    return $self->seq;
  }
}


sub getLocAsCracFormat {
  my $self = shift;
  return $self->rname."|".$self->getStrand.",".$self->pos;
}


sub getPatch {
  my $self = shift;
  my $line_number = shift;
  croak("Cannot generate patch without the line number in argument") unless defined $line_number;
  if($self->updatedLine ne $self->line) {
    my $line1 = $self->line;
    my $line2 = $self->updatedLine;
    chomp($line1);
    chomp($line2);
    return "@@ -$line_number,1 +$line_number,1 @@\n-$line1\n+$line2";
  } else {
    return 0;
  }
}



sub line {
  my $self = shift;
  return $self->{line};
}


sub updatedLine {
  my $self = shift;
  my $updated_line = shift;
  if(defined $updated_line) {
    $self->{updated_line} = $updated_line;
    return 1;
  } elsif (!defined $self->{updated_line}) {
    return $self->line;
  } else {
    return $self->{updated_line};
  }
}


sub qname {
  my $self = shift;
  my $new_qname = shift;
  if(defined $new_qname) {
    $self->{qname} = $new_qname;
  }
  return $self->{qname};
}


sub flag {
  my $self = shift;
  my $new_flag = shift;
  if(defined $new_flag) {
    $self->{flag} = $new_flag;
  }
  return $self->{flag};
}


sub rname {
  my $self = shift;
  my $new_rname = shift;
  if(defined $new_rname) {
    $self->{rname} = $new_rname;
  }
  return $self->{rname};
}


sub chr {
  my $self = shift;
  $self->rname(@_);
}


sub pos {
  my $self = shift;
  my $new_pos = shift;
  if(defined $new_pos) {
    $self->{pos} = $new_pos;
  }
  return $self->{pos};
}


sub mapq {
  my $self = shift;
  my $new_mapq = shift;
  if(defined $new_mapq) {
    $self->{mapq} = $new_mapq;
  }
  return $self->{mapq};
}


sub cigar {
  my $self = shift;
  my $new_cigar = shift;
  if(defined $new_cigar) {
    $self->{cigar} = $new_cigar;
  }
  return $self->{cigar};
}


sub rnext {
  my $self = shift;
  my $new_rnext = shift;
  if(defined $new_rnext) {
    $self->{rnext} = $new_rnext;
  }
  return $self->{rnext};
}


sub pnext {
  my $self = shift;
  my $new_pnext = shift;
  if(defined $new_pnext) {
    $self->{pnext} = $new_pnext;
  }
  return $self->{pnext};
}


sub tlen {
  my $self = shift;
  my $new_tlen = shift;
  if(defined $new_tlen) {
    $self->{tlen} = $new_tlen;
  }
  return $self->{tlen};
}


sub seq {
  my $self = shift;
  my $new_seq = shift;
  if(defined $new_seq) {
    $self->{seq} = $new_seq;
  }
  return $self->{seq};
}


sub qual {
  my $self = shift;
  my $new_qual = shift;
  if(defined $new_qual) {
    $self->{qual} = $new_qual;
  }
  return $self->{qual};
}


sub getOptionalField {
  my $self = shift;
  my $field = shift;
  croak("Missing \$field argument to call getOptionalField") unless defined $field;
  return $self->{extended_fields}{$field};
}



sub getChimericAlignments {
    my $self = shift;
    # check the existence of the SA field in the SAM line
    if (defined $self->{extended_fields}{SA}){
	my @array_hash;
	my (@SA_alignments) = split(/;/,$self->{extended_fields}{SA});
	for (my $i=0 ;  $i < scalar @SA_alignments ; $i++){
	    my ($chr,$pos,$strand,$cigar,$mapq,$edist) = split(/,/,$SA_alignments[$i]);
	    # strand switch from "+,-" to "1,-1"
	    if ($strand eq '+'){
		$strand = 1;
	    }else{
		$strand = -1;
	    }
	    my $hash = { chr => $chr, 
			 pos => $pos,
			 strand => $strand,
			 cigar => $cigar,
			 mapq => $mapq,
			 edist => $edist};
	    push(@array_hash,$hash);
	}
	return \@array_hash;
    }
    return undef;
}


sub getCigarOperatorsCount {
  my $self = shift;
  my @ops = $self->cigar =~ /(\d+\D)/g;
  my %ops_occ;
  foreach (@ops) {
    my ($nb,$op) = $_ =~ /(\d+)(\D)/;
    $ops_occ{$op} = 0 unless defined $ops_occ{$op};
    $ops_occ{$op} += $nb;
  }
  return \%ops_occ;
}


sub pSupport {
  my $self = shift;
  $self->loadSamDetailed;
  return $self->{sam_detailed}{p_support};
}


sub pLoc {
  my $self = shift;
  $self->loadSamDetailed;
  return $self->{sam_detailed}{p_loc};
}


sub pairedChimera {
  my $self = shift;
  $self->loadPaired();
  if(defined $self->{extended_fields}{XP}{chimera}) {
    my ($crac_loc1,$crac_loc2) = split(":",$self->{extended_fields}{XP}{chimera});
    return (expandCracLoc($crac_loc1),expandCracLoc($crac_loc2));
  } else {
    return undef;
  }
}


sub isPairedClassified {
  my $self = shift;
  my $class = shift;
  $self->loadPaired();

  if(defined $self->{extended_fields}{XP}{loc} && ref($self->{extended_fields}{XP}{loc}) ne 'HASH') {
    my ($uniq,$dupli,$multi) = split(":",$self->{extended_fields}{XP}{loc});
    $self->{extended_fields}{XP}{loc} = {unique => $uniq, duplicated => $dupli, multiple => $multi};

  }
  return $self->{extended_fields}{XP}{loc}{$class};
}



sub genericInfo {
  my ($self,$key,$value) = @_;
  if(!defined $key) {
    die "You need to provide a key in order to set or get a genericInfo\n";
  } elsif(defined $value) {
    $self->{genericInfo}{$key} = $value;
  } else {
    return $self->{genericInfo}{$key};
  }
}


sub isClassified {
  my $self = shift;
  my $class = shift;
  
  croak "Missing class argument" unless defined $class;

  if($class eq "unique") {
    return $self->{extended_fields}{XU};
  } elsif($class eq "duplicated") {
    return $self->{extended_fields}{XD};
  } elsif($class eq "multiple") {
    return $self->{extended_fields}{XM};
  } elsif($class eq "normal") {
    defined $self->{extended_fields}{XN} ? return $self->{extended_fields}{XN} == 1 : return undef;
  } elsif($class eq "almostNormal") {
    defined $self->{extended_fields}{XN} ? return $self->{extended_fields}{XN} == 2 : return undef;
  } else {
    croak "Class argument ($class) does not match any case";
  }
}


sub events {
  my $self = shift;
  my $event_type = lc shift;
  $self->loadEvents();#$event_type);
  if(defined $self->{events}{$event_type}) {
    return $self->{events}{$event_type};
  } else {
    return [];
  }
}


sub loadEvents {
  my $self = shift;
  my $event_type_to_load = shift;
  ## TODO avoid double loading when doing lazy loading
  #if(defined $event_type_to_load && defined $self->{$event_type_to_load}{loaded}) {
  #  return 0;
  #}
  if(!defined $self->{events} && defined $self->{extended_fields}{XE}) { 
    # Init events
    my @events = split(";",$self->{extended_fields}{XE});
    foreach my $event (@events) {
      my ($event_id,$event_break_id,$event_type,$event_infos) = $event =~ /([^:]+):([^:]+):([^:]+):(.*)/g;
      $event_type = lc $event_type;
      next if(defined $event_type_to_load && $event_type ne $event_type_to_load);
      if(defined $event_id) {
        my %event_hash;
        if($event_type eq 'junction') {
          my ($type,$pos_read,$loc,$gap) = split(':',$event_infos);
          my ($chr,$pos,$strand) = expandCracLoc($loc);
          %event_hash = ( type => $type,
                           pos => $pos_read,
                           loc => {chr => $chr, pos => $pos, strand => $strand},
                           gap => $gap,
                         );
        } elsif($event_type eq 'ins' || $event_type eq 'del') {
          my ($score,$pos_read,$loc,$nb) = split(':',$event_infos); 
          my ($chr,$pos,$strand) = expandCracLoc($loc);
          %event_hash = ( score => $score,
                      pos => $pos_read,
                      loc => {chr => $chr, pos => $pos, strand => $strand},
                      nb => $nb,
                    );
        } elsif($event_type eq 'snp') {
          my ($score,$pos_read,$loc,$expected,$actual) = split(':',$event_infos); 
          my ($chr,$pos,$strand) = expandCracLoc($loc);
          %event_hash = ( score => $score,
                      pos => $pos_read,
                      loc => {chr => $chr, pos => $pos, strand => $strand},
                      expected => $expected,
                      actual => $actual,
                    );
        } elsif($event_type eq 'error') {
          my ($type,$pos,$score,$other1,$other2) = split(':',$event_infos); 
          %event_hash = ( score => $score,
                      pos => $pos,
                      type => $type,
                      other1 => $other1,
                      other2 => $other2,
                    );
        } elsif($event_type eq 'chimera') {
          my ($pos_read,$loc1,$loc2,$class,$score) = split(':',$event_infos); 
          my ($chr1,$pos1,$strand1) = expandCracLoc($loc1);
          my ($chr2,$pos2,$strand2) = expandCracLoc($loc2);
          %event_hash = ( pos => $pos_read,
                      loc1 => {chr => $chr1, pos => $pos1, strand => $strand1},
                      loc2 => {chr => $chr2, pos => $pos2, strand => $strand2},
                      class => $class,
                      score => $score,
                    );
        } elsif($event_type eq 'undetermined') {
          %event_hash = ( message => $event_infos,
                    );
        } elsif($event_type eq 'bioundetermined') {
          my ($pos,$message) = $event_infos =~ /([^:]+):(.*)/; 
          %event_hash = ( pos => $pos,
                      message => $message,
                    );
        }
        if (keys %event_hash > 1) {
          $event_hash{event_id} = $event_id;
          $event_hash{break_id} = $event_break_id;
          $event_hash{event_type} = $event_type;
          $self->addEvent(\%event_hash);
        }
      }
    }
    ## If we have only load a specific event type
    #if(defined $event_type_to_load) {
    #  $self->{$event_type_to_load}{loaded} = 1;
    ## Else we have load every events.
    #} else {
    #  $self->{events}{loaded} = 1;
    #}
  }
}


sub addEvent {
  my $self = shift;
  my $event = shift;
  my $event_type = $event->{event_type};
  if(defined $self->{events}{$event_type}) {
    push(@{$self->{events}{$event_type}},$event);
  } else {
    $self->{events}{$event_type} = [$event];
  }
}


sub removeEvent {
  my $self = shift;
  my $delete_event = shift;
  my $type = $delete_event->{event_type};
  if(defined $type && defined $self->{events}{$type}) {
    my $i = 0;
    foreach my $event (@{$self->{events}{$type}}) {
      if($event eq $delete_event) {
        splice @{$self->{events}{$type}}, $i, 1;
        return 1;
      }
      $i++;
    }
  }
  return 0;
}


sub updateEvent {
  my $self = shift;
  my $event = shift;
  my $new_event_type = shift;
  my %new_event = @_;

  # Update new event with old break id and event id
  $new_event{event_type} = $new_event_type;
  $new_event{event_id} = $event->{event_id};
  $new_event{break_id} = $event->{break_id};

  if($self->removeEvent($event)) {
    # Catch warnings on string concatenation that correspond to missing
    # field in the hash for the event to update
    local $SIG{'__WARN__'} = sub {croak("Invalid event hash for event type '$new_event_type'");};
    my $base_XE = 'XE:Z:'.$new_event{event_id}.':'.$new_event{break_id};
    my $new_XE = $base_XE . ':';
    if($new_event_type eq 'Junction') {
        my $loc = compressCracLoc($new_event{loc}{chr},$new_event{loc}{pos},$new_event{loc}{strand});
        $new_XE .= $new_event_type.':'.
                   $new_event{type}.':'.
                   $new_event{pos}.':'.
                   $loc.':'.
                   $new_event{gap};
    } elsif($new_event_type eq 'Ins' || $new_event_type eq 'Del') {
        my $loc = compressCracLoc($new_event{loc}{chr},$new_event{loc}{pos},$new_event{loc}{strand});
        $new_XE .= $new_event_type.':'.
                   $new_event{score}.':'.
                   $new_event{pos}.':'.
                   $loc.':'.
                   $new_event{nb};
    } elsif($new_event_type eq 'SNP') {
        my $loc = compressCracLoc($new_event{loc}{chr},$new_event{loc}{pos},$new_event{loc}{strand});
        $new_XE .= $new_event_type.':'.
                   $new_event{score}.':'.
                   $new_event{pos}.':'.
                   $loc.':'.
                   $new_event{expected}.':'.
                   $new_event{actual};
    } elsif($new_event_type eq 'Error') {
        my $loc = compressCracLoc($new_event{loc}{chr},$new_event{loc}{pos},$new_event{loc}{strand});
        $new_XE .= $new_event_type.':'.
                   $new_event{type}.':'.
                   $new_event{pos}.':'.
                   $new_event{score}.':'.
                   $new_event{other1}.':'.
                   $new_event{other2};
    } elsif($new_event_type eq 'chimera') {
        my $loc1 = compressCracLoc($new_event{loc1}{chr},$new_event{loc1}{pos},$new_event{loc1}{strand});
        my $loc2 = compressCracLoc($new_event{loc2}{chr},$new_event{loc2}{pos},$new_event{loc2}{strand});
        $new_XE .= $new_event_type.':'.
                   $new_event{pos}.':'.
                   $loc1.':'.
                   $loc2;
    } elsif($new_event_type eq 'Undetermined') {
        $new_XE .= $new_event_type.':'.
                   $new_event{message};
    } elsif($new_event_type eq 'BioUndetermined') {
        $new_XE .= $new_event_type.':'.
                   $new_event{pos}.':'.
                   $new_event{message};
    } else {
      croak("Unknown type of event : $new_event_type");
    }
    $self->addEvent(\%new_event);
    my $new_line = $self->updatedLine;
    $new_line =~ s/($base_XE:[^\t]*)/$new_XE/;
    $self->updatedLine($new_line);
  } else {
    croak('Event not find');
  }
}


sub loadSamDetailed {
  my $self = shift;
  if(!defined $self->{sam_detailed}) {
    #my ($detailed) = $self->line =~ /XR:Z:([^\s]+)/g;
    my $detailed = $self->{extended_fields}{XR};
    my @detailed_fields = split(";",$detailed); 
    foreach (@detailed_fields) {
      my ($k,$v) = split('=',$_);
      if($k eq 'p_loc') {
        $self->{sam_detailed}{p_loc} = $v;
      } elsif($k eq 'p_support') {
        $self->{sam_detailed}{p_support} = $v;
      } else {
        carp("Unknown sam detailed field : $k");
      }
    }
    $self->{sam_detailed}{loaded} = 1;
  }
}


sub loadPaired {
  my $self = shift;
  # If XP fields exist and we haven't load it already
  if(defined $self->{extended_fields}{XP} && ref($self->{extended_fields}{XP}) ne 'HASH') {
    my @paired_fields = split(";",$self->{extended_fields}{XP});
    $self->{extended_fields}{XP} = {}; # Chamge type of XP exetended field from scalar to hash ref
    foreach (@paired_fields) {
      my($key,$value) = split(":",$_,2);
      $self->{extended_fields}{XP}{$key} = $value;
    }
  }
}


sub expandCracLoc {
  my $loc = shift;
  my($chr,$strand,$pos) = $loc =~ /(\S+)\|(\S+)?,(\S+)?/; 
  return ($chr,$pos,$strand);
}


sub compressCracLoc {
  my ($chr,$pos,$strand) = @_;
  confess("Missing argument") unless defined $chr && defined $pos && defined $strand;
  return $chr."|".$strand.",".$pos;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::SAMReader::SAMline - The object for manipulation a SAM line.

=head1 VERSION

version 1.251

=head1 SYNOPSIS

  use CracTools::SAMReader::SAMline;

  $sam_line = CracTools::SAMReader::SAMline->new($line);

=head1 DESCRIPTION

An object for easy acces to SAM line fields. See SAM Specifications for more informations :
http://samtools.sourceforge.net/SAM1.pdf

=head1 Variables

=head2 %flags

SAM flags :

=over 2

=item * MULTIPLE_SEGMENTS => 1

=item * PROPERLY_ALIGNED => 2

=item * UNMAPPED => 4,

=item * NEXT_UNMAPPED => 8,

=item * REVERSE_COMPLEMENTED => 16,

=item * NEXT_REVERSE_COMPLEMENTED => 32,

=item * FIRST_SEGMENT => 64,

=item * LAST_SEGMENT => 128,

=item * SECONDARY_ALIGNMENT => 256,

=item * QUALITY_CONTROLS_FAILED => 512,

=item * PCR_DUPLICATED => 1024,

=item * CHIMERIC_ALIGNMENT => 2048,

=back

=head1 STATIC PARSING METHODS

These methods can be used without creating an CracTools::SAMReader::SAMline object.
They are designed to provided efficient performance when parsing huge SAM files,
because creating object in Perl can be long and useless for some purposes.

=head2 hasEvent

  Arg [1] : String - SAM line
  Arg [2] : eventType

=head1 Methods

=head2 new

  Arg [1] : String - SAM line in TAB-separated format.

  Example     : $sam_line = CracTools::SAMline->new$($line);
  Description : Create a new CracTools::SAMline obect.
  ReturnType  : CracTools::SAMline
  Exceptions  : none

=head2 isFlagged

  Arg [1] : Integer - The flag to test (1,2,4,8, ... ,1024)

  Example     : if($SAMline->isFlagged($fags{unmapped}) {
                  DO_SOMETHING... 
                };
  Description : Test if the line has the flag in parameter setted.
  ReturnType  : Boolean
  Exceptions  : none

=head2 getStrand

  Example     : $strand = $SAMline->getStrand(); 
  Description : Return the strand of the SAMline :
                - "1" if forward strand
                - "-1" if reverse strand
  ReturnType  : 1 or -1
  Exceptions  : none

=head2 getOriginalSeq

  Descrition   : Return the original sequence as it was in the FASTQ file.
                 In fact we reverse complemente the sequence if flag 16 is raised.

=head2 getLocAsCracFormat

  Example     : $loc = $SAMline->getLocAsCracFormat(); 
  Description : Return the location of the sequence using CRAC format : "chr|strand,position".
                For example : X|-1,2154520
  ReturnType  : String
  Exceptions  : none

=head2 getPatch

  Description : If the SAMline has been modified, this method will generate
                a patch in UnifiedDiff format that represent the changes.
  ReturnType  : String (patch) if line has changed, False (0) either.
  Exceptions  : none

=head1 GETTERS AND SETTERS

=head2 line

  Description : Getter for the whole SAMline as a string.
  ReturnType  : String
  Exceptions  : none

=head2 updatedLine

  Description : Getter/Setter for the updated line.
                If there is not updated line, this method return
                the original SAM line.
  RetrunType  : String

=head2 qname

  Description : Getter/Setter for attribute qname
  ReturnType  : String
  Exceptions  : none

=head2 flag

  Description : Getter/Setter for attribute flag
  ReturnType  : String
  Exceptions  : none

=head2 rname

  Description : Getter/Setter for attribute rname (chromosome for eucaryotes)
  ReturnType  : String
  Exceptions  : none

=head2 chr

  Description : Getter/Setter for attribute rname (Alias)
  ReturnType  : String
  Exceptions  : none

=head2 pos

  Description : Getter/Setter for attribute pos (position of the sequence)
  ReturnType  : String
  Exceptions  : none

=head2 mapq

  Description : Getter/Setter for attribute mapq (mapping quality)
  ReturnType  : String
  Exceptions  : none

=head2 cigar

  Description : Getter/Setter for attribute cigar (see SAM doc)
  ReturnType  : String
  Exceptions  : none

=head2 rnext

  Description : Getter/Setter for attribute rnext (see SAM doc)
  ReturnType  : String
  Exceptions  : none

=head2 pnext

  Description : Getter/Setter for attribute pnext (see SAM doc)
  ReturnType  : Integer
  Exceptions  : none

=head2 tlen

  Description : Getter/Setter for attribute tlen (sequence length)
  ReturnType  : Integer
  Exceptions  : none

=head2 seq

  Description : Getter/Setter for attribute seq (the sequence).
                Please use getOriginalSeq if you want to retrieve the oriented
                sequence, that what you need in most cases.
  ReturnType  : String
  Exceptions  : none

=head2 qual

  Description : Getter/Setter for attribute qual (sequence quality)
  ReturnType  : String
  Exceptions  : none

=head2 getOptionalField

  Example     : 
  Description : 
  ReturnType  : 

=head2 getChimericAlignments

  Description : Parser of SA fields of SAM file in order to find chimeric reads
  ReturnType  : Array reference
                Elements are hash [ chr    => String, 
                                    pos    => int, 
                                    strand => 1/-1, 
                                    cigar  => String,
                                    mapq   => int,
                                    edist  => int
                                  ]

=head2 getCigarOperatorsCount

  Example     : my %cigar_counts = %{ $sam_line->getCigarOperatorsCount() };
                print "nb mismatches; ",$cigar_counts{X},"\n";
  Description : Return a hash reference where the keys are the cigar operators and the values
                the sum of length associated for each operator.
                For cigar 5S3M1X2M10S, getCigarOperatorsCounts() will retrun :
                { 'S' => 15,
                  'M' => 5,
                  'X' => 1,
                };
  ReturnType  : Hash reference 

=head2 pSupport

  Description : Return the support profile of the read if the SAM file has been generated with
                CRAC option --detailed
  ReturnType  : String

=head2 pLoc

  Description : Return the location profile of the read if the SAM file has been generated with
                CRAC option --detailed
  ReturnType  : String

=head2 pairedChimera

  Description : return the chimeric coordinates of the paired chimera associated to this read if there is one

  ReturnType  : array(chr1,pos1,strand1,chr2,pos2,strand2) or undef

=head2 isPairedClassified

  Arg [1] : String - The class to test :
            - "unique"
            - "duplicated"
            - "multiple"

  Description : Test paired-end read clasification

  ReturnType  : Boolean

=head2 genericInfo

  [1] : Key of the generic info
  [2] : (Optional) Value of the generic info

  Description : Getter/Setter enable to store additional (generic) information 
                about the SAMline as a Key/Value. 
  Example : # Set a generic info
            $read->genericInfo("foo","bar")

            # Get a generic info
            print $read->genericInfo("foo"); # this will print "bar"
  ReturnType : ?
  Exceptions : none

=head2 isClassified

  Arg [1] : String - The class to test :
            - "unique"
            - "duplicated"
            - "multiple"
            - "normal"
            - "almostNormal"

  Example     : if($sam_line->isClassified('normal')) {
                  DO_SOMETHING;
                }
  Description : Test if the line is classified according to the parameter value.
  ReturnType  : Boolean
  Exceptions  : none

=head2 events

  Arg [1] : String - The event type to return :
            - Junction
            - Ins
            - Del
            - SNP
            - Error
            - Chimera
            - Undetermined
            - BioUndetermined
            - ... (see CRAC SAM format specifications for more informations).
  Example     : my @junctions = @{$line->events('Junction')};
                foreach my $junction (@junctions) {
                  print "Foud Junction : [type : $junction->{type}, loc : $junction->{loc}, gap : $junction->{gap}]\n";
                } 
  Description : Return all events of the type specified in parameter
  ReturnType  : Array reference
  Exceptions  : none

=head1 PRIVATE METHODS

=head2 loadEvents

  Example     : $sam_line->loadEvents();
  Description : Loading of events attributes
  ReturnType  : none
  Exceptions  : none

=head2 addEvent

  Arg [1] : String - The event type
  Arg [2] : Hash reference - The event object
  Example     : $line->addEvent($event_type,\%event); 
  Description : Return all events of the type specified in parameter
  ReturnType  : none
  Exceptions  : none

=head2 removeEvent 

  Arg [1] : Hash reference - The event object

  Description : Remove the event from the event hash and from the line.

=head2 updateEvent

=head2 loadSamDetailed

  Example     : $sam_line->loadSamDetailed();
  Description : Loading of sam detaileds attributes
  ReturnType  : none
  Exceptions  : none

=head2 loadPaired

  Example     : $sam_line->loadPaired();
  Description : Loading of sam detaileds attributes
  ReturnType  : none
  Exceptions  : none

=head2 expandCracLoc

  Arg [1] : String - Localisation in crac format : Chromosome|strand,position
            Ex : X|-1,2332377

  Description : Extract Chromosme, position and strand as separated variable from
                the localisation in CRAC format.
  ReturnType  : Array($chromosome,$position,$strand)

=head2 compressCracLoc

  Arg [1] : String - Chromosome
  Arg [2] : Integer - Postition
  Arg [3] : Integer (1,-1) - Strand

  Description : Reverse function of "expandCracLoc"
  ReturnType  : String (localisation in CRAC format)

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
