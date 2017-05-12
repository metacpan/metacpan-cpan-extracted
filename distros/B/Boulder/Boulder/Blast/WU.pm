package Boulder::Blast::WU;

# WUBLAST file format parsing

=head1 NAME

Boulder::Blast::WU - Parse and read WU-BLAST files

=head1 SYNOPSIS

Not for direct use.  Use Boulder::Blast instead.

=head1 DESCRIPTION

Specialized parser for WUBLAST format BLAST output.  Loaded
automatically by Boulder::Blast.

=head1 SEE ALSO

L<Boulder>, L<Boulder::GenBank>, L<Boulder::Blast>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 1998 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Stone;
use Boulder::Stream;
use Carp;
use vars qw($VERSION @ISA);
@ISA = 'Boulder::Blast';

$VERSION = 1.00;

sub _read_record {
  my $self = shift;
  my $fh   = shift;
  my $stone = shift;

  # we don't find out about the name of the database or the parameters until we
  # get to the bottom of the file.  Too bad.
  
  # loop until we find the query name
  my $line;
  do { 
    $line = <$fh>;
  } until $line=~/^Query=\s+(\S+)/;
  
  croak "Couldn't find query line!" unless $1;
  $stone->insert(Blast_query => $1);

  do { 
    $line = <$fh>;
  } until $line=~/([\d,]+) letters/;

  croak "Couldn't find query length!" unless $1;
  (my $len = $1) =~ s/,//g;
  $stone->insert(Blast_query_length => $len);

  # Read down to the first hit, if any.  If we hit /^Parameters/, then we had no
  # hits.
  while (<$fh> ) {
    last if /^(>|Parameters)/;
  }
  
  if (/^>/) {  # we found some hits
    my $hits = $self->parse_hits($_);
    $stone->insert(Blast_hits => $hits);
  }

  # At this point, one way or another, we're pointing at the Parameters
  # line.  We create a parameter stone to hold the results
  my $parms = new Stone;
  while (<$fh>) {
    chomp;
    last if /^Statistics/;
    $parms->insert(Ctxfactor => $1) if /ctxfactor=(\S+)/;
    $parms->insert(Gapall=>'yes')   if /gapall/;
    $parms->insert(Hspmax=>$1)      if /hspmax=(\S+)/;
    $parms->insert(Expectation=>$1) if /E=(\S+)/;
    $parms->insert(Matrix=>$1)      if /^\s+\+[0-3]\s+0\s+(\S+)/ && !$parms->get('Matrix'); # borscht
  }
  $stone->insert(Blast_parms => $parms);

  # Now we should be pointing at statistics
  while (<$fh>) {
    $stone->insert(Blast_db       => $1) if /Database: (.*)/;
    $stone->insert(Blast_db_title => $1) if /Title: (.*)/;
    $stone->insert(Blast_db_date  => $1) if /Posted date:\s+(.*)/;
    last if /End:/;
  }

  # finally done!
  $stone;
}

# parse the hits and HSPs
sub parse_hits {
  my $self = shift;
  $_ = shift;
  my $fh = $self->_fh;
  my (@hits,@hsps,$accession,$orientation,$hit,$hsp);
  my ($qstart,$qend,$tstart,$tend);
  my ($query,$match,$target,$done,$new_hit,$new_hsp);
  my $signif = 9999;
  my $expect = 9999;
  my $ident  = 0;

  while (!$done) {
    chomp;
    next unless length($_);

    $done    = /^Parameters/; # here's how we get out of the loop
    $new_hit = /^>(\S+)/;
    $new_hsp = $accession && /Score = (\d+) \((\S+) bits\)/;

    # hit a new HSP section
    if ( $done || $new_hit || $new_hsp ) {
      if ($hsp) {
	croak "base alignment is out of whack" 
	  unless length($query) == length($target);
	$hsp->insert(Query       => $query,
		     Subject     => $target,
		     Alignment   => substr($match,0,length($query)),
		    );
	$hsp->insert(Query_start   => $qstart,
		     Query_end     => $qend,
		     Subject_start => $tstart,
		     Subject_end   => $tend,
		     Length        => 1 + $qend - $qstart,
		     Orientation   => $tend > $tstart ? 'plus' : 'minus',
		    );
	push(@hsps,$hsp);
	undef $hsp;
      }
      if ($new_hsp) {
	$hsp = new Stone;
	$hsp->insert(Score => $1, Bits => $2);
	($qstart,$qend,$tstart,$tend) = (undef,undef,undef,undef);  # undef all
	($query,$match,$target) = (undef,undef,undef);  # these too
      }
    }
    
    # hit a new subject section
    if ( $done || $new_hit ) {  
      $accession = $1;
      if ($hit) {
	$hit->insert(Hsps     => \@hsps,
		     Signif   => $signif,
		     Identity => $ident,
		     Expect   => $expect,
		    ) if @hsps;
	undef @hsps;
	push(@hits,$hit);
	($signif,$expect,$ident) = (9999,9999,0); # reset max values
      }
      if ($new_hit) {
	$hit = new Stone;
	$hit->insert(Name => $accession);
	next;
      }
    }
    
    # hit the length = line
    if (/Length\s*=\s*([\d,]+)/) {
      (my $len = $1) =~ s/,//g;
      $hit->insert(Length => $len);
      next;
    }

    # hit the Plus|Minus Strand line
    if (/(Plus|Minus) Strand HSPs/) {
      $orientation = lc $1;
      next;
    }

    # None of the following is relevant unless $hsp is defined
    next unless $hsp;

    if (/Expect = ([+e\d\.-]+)/) {
      $hsp->insert(Expect => $1);
      $expect = $1 < $expect ? $1 : $expect;
    }

    if (/P(?:\(\d+\))? = (\S+)/) {
      $hsp->insert(Signif => $1);
      $signif = $1 < $signif ? $1 : $signif;
    }
    
    if (/Identities = \S+ \((\d+)%?\)/) {
      my $idn = $1 * 0.01;
      $hsp->insert(Identity => $idn);
      $ident = $idn > $ident ? $idn : $ident;
    }

    $hsp->insert(Positives => $1)   if /Positives = \S+ \((\S+)\)/;
    $hsp->insert(Strand => $1)      if /Strand =\s+([^,]+)/;
    $hsp->insert(Frame => $1)       if /Frame =\s+([^,]+)/;

    # process the query sequence
    if (/^Query:\s+(\d+)\s+(\S+)\s+(\d+)/) {
      $qstart ||= $1;
      $qend = $3;
      $query .= $2;
      next;
    }

    # process the target sequence
    if (/^Sbjct:\s+(\d+)\s+(\S+)\s+(\d+)/) {
      $tstart ||= $1;
      $tend     = $3;
      $target  .= $2;
      next;
    }

    # anything else is going to be the match string
    # this is REALLY UGLY because we have to extract absolute
    # positions
    $match .= substr($_,13,60) if $query;
  } continue {
    $_ = <$fh>;
  }

  return \@hits;
}

1;

