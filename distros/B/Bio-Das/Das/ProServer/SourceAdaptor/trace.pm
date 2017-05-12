#########
# Author: jc3
# Maintainer: jc3
# Created: 2003-09-17
# Last Modified: 2003-09-17
# Provides DAS features for Trace file Information.

package Bio::Das::ProServer::SourceAdaptor::trace;
=head1 AUTHOR

Jody Clements <jc3@sanger.ac.uk>.

based on modules by 

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it a nd/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

my $root;

BEGIN {
  $root = $ENV{'ENS_ROOT'};
  if(!defined $ENV{'ENSEMBL_SPECIES'} || $ENV{'ENSEMBL_SPECIES'} eq ""){
    print STDERR qq(No species defined... default to Homo_sapiens\n);
    $ENV{'ENSEMBL_SPECIES'} = "Homo_sapiens" ;
  }
  print STDERR qq(species = $ENV{'ENSEMBL_SPECIES'}\n);
  unshift(@INC,"$root/modules");
}

use strict;
use IndexSupport;
use base qw(Bio::Das::ProServer::SourceAdaptor);
use Time::HiRes qw(gettimeofday);

sub init{
  my $self = shift;
  $self->{'capabilities'} = {
			     'features' => '1.0',
			     'stylesheet' => '1.0',
			    };
  $self->{'link'} = "http://trace.ensembl.org/perl/traceview?traceid=";
  $self->{'linktxt'} = "more information";
}

sub length{
  my ($self,$seg) = @_;
   if ($seg =~ /^(10|20|(1?[1-9])|(2?[12])|[XY])$/i && !$self->{'_length'}->{$seg}){
  
     my $conf = IndexSupport->new("$root/conf",'','Homo_sapiens');
     my($length) = $conf->{'dbh'}->selectrow_array(qq(
                       SELECT length FROM seq_region where name = ?
                       ), {}, $seg );


    $self->{'_length'}->{$seg} = $length;
   }
 return $self->{'_length'}->{$seg};
}


sub das_stylesheet{
  my ($self) = @_;

  my $response = qq(<!DOCTYPE DASSTYLE SYSTEM "http://www.biodas.org/dtd/dasstyle.dtd">
		     <DASSTYLE>
		      <STYLESHEET version="1.0">
		       <CATEGORY id="trace">
		        <TYPE id="Forward">
		         <GLYPH>
		          <FARROW>
		           <HEIGHT>2</HEIGHT>
		           <BGCOLOR>black</BGCOLOR>
                           <FGCOLOR>red</FGCOLOR>
		           <FONT>sanserif</FONT>
		           <BUMP>0</BUMP>
		          </FARROW>
		         </GLYPH>
		        </TYPE>
		        <TYPE id="Reverse">
		         <GLYPH>
		          <RARROW>
		           <HEIGHT>2</HEIGHT>
		           <BGCOLOR>black</BGCOLOR>
                           <FGCOLOR>black</FGCOLOR>
		           <FONT>sanserif</FONT>
                           <BUMP>0</BUMP>
		          </RARROW>
		         </GLYPH>
		        </TYPE>
		       </CATEGORY>
		      </STYLESHEET>
		     </DASSTYLE>\n);

  return $response;
}

sub build_features{
  my  $t0 = gettimeofday;
  
  my ($self,$opts) = @_;
  my $segid     = $opts->{'segment'};
  my $start     = $opts->{'start'};
  my $end       = $opts->{'end'};
  my $assm_name = $self->config->{'assm_name'};
  my $assm_ver  = $self->config->{'assm_ver'};
  my @features  = ();

  if ($segid !~ /^(10|20|(1?[1-9])|(2?[12])|[XY])$/i){
    return @features;
  }


#####
#  if $end - $start = too big then return some sort of average 
#  density across the area selected. this should reduce the load
#  times when a large sequence is requested. Maybe anything greater
#  than a kilobase.
#####
  
  if (!$end){
    return @features;
  }

my $query = qq(SELECT
                ms.snp_rea_id_read      as read_id,
                sr.readname             as readname,
                ms.contig_match_start   as contig_start,
                ms.contig_match_end     as contig_end,
                ms.contig_orientation   as read_ori,
                ms.read_match_start     as read_start,
                ms.read_match_end       as read_end,
                ssm.start_coordinate    as chr_start,
                ssm.end_coordinate      as chr_end,
                ssm.contig_orientation  as contig_ori
        FROM    chrom_seq cs,
                seq_seq_map ssm,
                mapped_seq ms,
                snp_read sr,
                database_dict dd
        WHERE   cs.database_seqname = '$segid'
        AND     dd.database_version = '$assm_ver'
        AND     dd.database_name = '$assm_name'
        AND     cs.database_source = dd.id_dict
        AND     cs.id_chromseq = ssm.id_chromseq
        AND     ssm.sub_sequence = ms.id_sequence
        AND     ms.snp_rea_id_read = sr.id_read
        AND     ssm.start_coordinate
                BETWEEN
                ($start - ms.contig_match_end + 1)
                AND
                ($end - ms.contig_match_start + 1)
);

my $t1 = gettimeofday;


my $trace = $self->transport->query($query);

my $t2 = gettimeofday;

  for my $trace (@$trace){
    my $url = $self->{'link'};
    my $link = $url . $trace->{'READNAME'};
    my $ori = ($trace->{'READ_ORI'} == 1)?"+":"-";
    my $type = ($trace->{'READ_ORI'} == 1)?"Forward":"Reverse";
    my $start = $trace->{'CHR_START'} + $trace->{'CONTIG_START'} - 1; 
    my $end = $trace->{'CHR_START'} + $trace->{'CONTIG_END'} - 1;

    if ($start > $end){
      ($start,$end) = ($end,$start);
    }
      
    push @features, {
		     'id'           => $trace->{'READNAME'},
		     'method'       => "trace",
		     'type'         => $type,
		     'ori'          => $ori,
		     'start'        => $start,
		     'end'          => $end,
		     'link'        => $link,
		     'linktxt'     => $self->{'linktxt'},
		     'typecategory' => "trace",
		    };
  }

my $t4 = gettimeofday;

  return @features;
}
1;
