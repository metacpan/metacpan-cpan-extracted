package CracTools::Interval::Query::File;
{
  $CracTools::Interval::Query::File::DIST = 'CracTools';
}
# ABSTRACT: Acts like CracTools::Interval::Query but read interval from files and return lines of the file matching the query.
$CracTools::Interval::Query::File::VERSION = '1.25';
use strict;
use warnings;

use Fcntl qw( SEEK_SET );
use Carp;

use parent 'CracTools::Interval::Query';


sub new {
  my $class = shift;

  # Call parent constructor
  my $self  = $class->SUPER::new(@_);

  my %args = @_;

  my $file = $args{file};
  croak "Missing file" unless defined $file;

  my $get_interval_sub = $args{get_interval_sub};

  my $header_skip = "#";
  $header_skip = $args{header_skip} if defined $args{header_skip};

  if(!defined $get_interval_sub) {
    my $type = $args{type};
    croak "Missing type" unless defined $type;
    if($type =~ /gff/i) {
      $get_interval_sub = \&_getIntervalsFromGFFLine;
    } elsif($type =~ /sam/i) {
      $get_interval_sub = \&_getIntervalsFromSAMLine;
      $header_skip = "@";
    } elsif($type =~ /bed/i) {
      $get_interval_sub = \&_getIntervalsFromBEDLine;
      $header_skip = "track";
    } else {
      croak "Undefined type ($type)";
    }
  }

  $self->{get_interval_sub} = $get_interval_sub;
  $self->{header_skip} = $header_skip;
  $self->{file} = $file;

  $self->_init();

  return $self;
}


sub _getIntervals {
  my ($self,$line) = @_;
  my $intervals = $self->{get_interval_sub}->($line);
  foreach (@$intervals) {$_->{strand} = 1 if !defined $_->{strand};}
  return $intervals;
}


sub _getLine {
  my ($self,$seek_pos) = @_;
  my $fh = $self->{filehandle};
  seek($fh,$seek_pos,SEEK_SET);
  my $line = <$fh>;
  chomp($line);
  return $line;
}


sub _processReturnValue {
  my $self = shift;
  my $val = shift;
  return $self->_getLine($val);
}

sub _init {
  my $self = shift;

  open(my $fh ,$self->{file}) or die ("Cannot open file ".$self->{file});

  my $curr_pos = tell($fh);
  my $header_line = 1;

  while(<$fh>) {

    # skip headers
    if($header_line) {
      if($_ =~ /^$self->{header_skip}/) {
        next;
      } else {
        $header_line = 0;
      }
    }

    my $pos = $curr_pos;
    my $intervals = $self->{get_interval_sub}->($_);

    foreach my $i (@$intervals) {
      if(defined $i->{low} && defined $i->{high} && defined $i->{seqname}) {

        # Add strand to default if not defined
        $i->{strand} = 1 unless defined $i->{strand};

        # We do not want any "chr" string before the reference sequence value
        $i->{seqname} =~ s/^chr//;

        $self->addInterval($i->{seqname},$i->{low},$i->{high},$i->{strand},$pos);
      }
    }

    $curr_pos = tell($fh);
  }

  $self->{filehandle} = $fh;
}



sub _getIntervalsFromGFFLine {
  my $line = shift;
  my @fields = split("\t",$line,8);
  return [{ seqname => $fields[0],
            low => $fields[3], 
            high => $fields[4],
            strand => CracTools::Utils::convertStrand($fields[6]),
          }];
}

sub _getIntervalsFromSAMLine {
  my $line = shift;
  my @fields = split("\t",$line,7);
  my $strand = 1;
  if($fields[1] & 16) {
    $strand = -1;
  }
  my $low = $fields[3];
  my $high = $low;
  my $intervals = [];
  my $i = 0;
  my @chunks = $fields[5] =~ /(\d+\D)/g;
  foreach (@chunks) {
    my ($nb,$op) = $_ =~ /(\d+)(\D)/;
    if( $op eq 'N' || $op eq 'D' ) {
      $intervals->[$i] = { seqname => $fields[2], 
                           low => $low, 
                           high =>$high,
                           strand => $strand,
                         };
      $i++;
      $low = $high + $nb;
      $high = $low;
    } elsif ($op ne 'S' || $op ne 'H' || $op ne 'I') {
      $high += $nb;
    }
  }
  # Add the last chunk
  $intervals->[$i] = { seqname => $fields[2], 
                       low => $low, 
                       high =>$high,
                       strand => $strand,
                     };
  return $intervals;
}


sub _getIntervalsFromBEDLine {
  my $line = shift;
  my @fields = split("\t",$line,13);
  if(@fields < 12) {
    return [{ seqname => $fields[0], low => $fields[1]+1, high => $fields[2] }];
  } else {
    my $intervals  = [];
    my $low = $fields[1];
    my $high;
    my @block_size = split(',',$fields[10]);
    my @block_start = split(',',$fields[11]);
    for(my $i = 0; $i < $fields[9]; $i++) {
      $low += $block_start[$i]; 
      $high = $low + $block_size[$i];
      $intervals->[$i] = { seqname => $fields[0],
                           low => $low + 1, 
                           high => $high,
                           strand => CracTools::Utils::convertStrand($fields[5]),
                         };
    }
    return $intervals;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Interval::Query::File - Acts like CracTools::Interval::Query but read interval from files and return lines of the file matching the query.

=head1 VERSION

version 1.25

=head1 TODO

Add an otpion that gives an method wich can parsed the return line.

=head2 new

  Arg [file] : String - file path
  Arg [type] : String - file type (bed,sam,gff,gtf)

  Example     : my $gffQuery = CracTools::GFF::Query->new('annotations.gff');
  Description : Create a new GFF Query object
  ReturnType  : CracTools::GFF::Query
  Exceptions  : none

=head2 _getIntervals

Return an array reference of intervals associated with the line.

Interval structure is described by get_interval_sub

=head2 _getLine

Return a line of a file at a give seek position.

=head2 _processReturnValue

  $self->_processReturnValue($val)

Overload _processReturnValue() method to retrieve lines from files using seek positions.

=head2 _getIntervalsFrom<FORMAT>Line

Interval must be :
1-base coordinate system
Closed intervals

=head2 _getIntervalsFromBEDLine

We transform BED annotation postions to base-1 positions, and closed intervals

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
