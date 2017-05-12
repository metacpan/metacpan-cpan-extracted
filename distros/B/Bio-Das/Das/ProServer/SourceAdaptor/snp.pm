#########
# Author: jc3
# Maintainer: jc3
# Created: 2003-06-20
# Last Modified: 2003-06-20
# Provides DAS features for SNP information.

package Bio::Das::ProServer::SourceAdaptor::snp;

=head1 AUTHOR

Jody Clements <jc3@sanger.ac.uk>.

based on modules by 

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
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



sub init{
  my $self = shift;
  $self->{'capabilities'} = {
			     'features' => '1.0',
			     'stylesheet' => '1.0',
			    };
  $self->{'link'} = "http://intweb.sanger.ac.uk/cgi-bin/humace/snp_report.pl?snp=";
  $self->{'linktxt'} = "more information";
}

#######
# gets rid of chromosome coordinates if multiple segments are present
#
#sub init_segments{
#  my ($self,$segments) = @_;
#  if (scalar @$segments > 1 && (grep {$_ =~ /^AL\d{6}/i} @$segments)){
#    @$segments = grep {$_ !~ /^(10|20|(1?[1-9])|(2?[12])|[XY])/i} @$segments;
#  }
#}

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
   <CATEGORY id="snp">
    <TYPE id="External Verified">
      <GLYPH>
        <BOX>
          <FGCOLOR>red</FGCOLOR>
          <FONT>sanserif</FONT>
          <BGCOLOR>black</BGCOLOR>
        </BOX>
      </GLYPH>
    </TYPE>
    <TYPE id="Sanger Verified">
      <GLYPH>
        <BOX>
          <FGCOLOR>green</FGCOLOR>
          <FONT>sanserif</FONT>
          <BGCOLOR>black</BGCOLOR>
        </BOX>
      </GLYPH>
    </TYPE>
    <TYPE id="Two-Hit">
      <GLYPH>
        <BOX>
          <FGCOLOR>blue</FGCOLOR>
          <FONT>sanserif</FONT>
          <BGCOLOR>black</BGCOLOR>
        </BOX>
      </GLYPH>
    </TYPE>
    <TYPE id="default">
      <GLYPH>
        <BOX>
          <FGCOLOR>darkolivegreen</FGCOLOR>
          <FONT>sanserif</FONT>
          <BGCOLOR>black</BGCOLOR>
        </BOX>
      </GLYPH>
    </TYPE>
  </CATEGORY>
</STYLESHEET>
</DASSTYLE>\n);

  return $response;
}

sub build_features{
  my ($self,$opts) = @_;
  my $segid       = $opts->{'segment'};
  my $start       = $opts->{'start'};
  my $end         = $opts->{'end'};
  my $assm_name = $self->config->{'assm_name'};
  my $assm_ver  = $self->config->{'assm_ver'};
  #my $restriction = "";
  my $query       = "";
  my @features    = ();

  if (defined $start && !$end){
    return @features;
  }

#  if (defined $start && defined $end){
#    $restriction = qq(AND     ms.POSITION
#                      BETWEEN	($start - ssm.START_COORDINATE - 99)
#	              AND	($end - ssm.START_COORDINATE + 1));

#  }

  if ($segid =~ /^(10|20|(1?[1-9])|(2?[12])|[XY])$/i){
    #get chromosome coordinates
    $query = qq(SELECT
                ss.ID_SNP                       as INTERNAL_ID,
                ss.DEFAULT_NAME                 as ID_DEFAULT,
                mapped_snp.POSITION + seq_seq_map.START_COORDINATE - 1
                                                as CHR_START,
                mapped_snp.END_POSITION + seq_seq_map.START_COORDINATE - 1
                                                as CHR_END,
                seq_seq_map.CONTIG_ORIENTATION  as CHR_STRAND,
                scd.DESCRIPTION                 as VALIDATED,
                ss.ALLELES                      as ALLELES,
                svd.DESCRIPTION                 as SNPCLASS,
                seq_seq_map.CONTIG_ORIENTATION  as CONTIG_ORI,
                ss.IS_PRIVATE                   as PRIVATE,
                snp.is_confirmed                as STATUS
        FROM    chrom_seq,
                database_dict,
                seq_seq_map,
                mapped_snp,
                snp,
                snpvartypedict svd,
                snp_confirmation_dict scd,
                snp_summary ss
        WHERE   chrom_seq.DATABASE_SEQNAME= '$segid'
        AND     database_dict.DATABASE_NAME = '$assm_name'
        AND     database_dict.DATABASE_VERSION = '$assm_ver'
        AND     database_dict.ID_DICT = chrom_seq.DATABASE_SOURCE
        AND     chrom_seq.ID_CHROMSEQ = seq_seq_map.ID_CHROMSEQ
        AND     seq_seq_map.SUB_SEQUENCE = mapped_snp.ID_SEQUENCE
        AND     mapped_snp.ID_SNP = ss.ID_SNP
        AND     ss.ID_SNP = snp.ID_SNP
        AND     snp.VAR_TYPE = svd.ID_DICT
        AND     ss.CONFIRMATION_STATUS = scd.ID_DICT
        AND     mapped_snp.POSITION
                BETWEEN
                ($start - seq_seq_map.START_COORDINATE - 99)
                AND
                ($end - seq_seq_map.START_COORDINATE + 1)
        ORDER BY
                CHR_START
);

  }
#  elsif ($segid !~ /^\w+\.\w+\.\w+\.\w+$/i){
#    #get contig coordinates
#    $query = qq(select distinct snp_name.snp_name as SNP_NAME,
#		(1 +(clone_seq_map.CONTIG_ORIENTATION * (mapped_snp.position -
#		clone_seq_map.START_COORDINATE))) as SNPPOS,
#		snp.is_confirmed as STATUS,
#		mapped_snp.id_snp as SNP_ID
#		from snp_name,
#		mapped_snp,
#		clone_seq_map,
#		snp,
#		clone_seq
#		where (mapped_snp.position between  clone_seq_map.START_COORDINATE and
#		clone_seq_map.END_COORDINATE
#		or mapped_snp.position between clone_seq_map.END_COORDINATE and
#		clone_seq_map.START_COORDINATE)
#		and  mapped_snp.id_sequence =  clone_seq_map.id_sequence
#		and clone_seq.DATABASE_SEQNAME = '$segid'
#		and clone_seq_map.ID_CLONESEQ = clone_seq.ID_CLONESEQ
#		and mapped_snp.id_sequence =  clone_seq_map.id_sequence
#		and mapped_snp.id_snp = snp.id_snp
#		and snp.id_snp = snp_name.id_snp
#		and snp_name.snp_name_type=1
#		order by SNPPOS);
#  }
  else{
    return @features;
  }

 my $snp = $self->transport->query($query);


for my $snp (@$snp){
  my $url = $self->{'link'};
  my $link = $url . $snp->{'ID_DEFAULT'};
  my $type = "Unknown";
  if ($snp->{'STATUS'} == 1){
    $type = "Sanger Verified";
  }
  elsif($snp->{'STATUS'} == 2){
    $type = "External Verified";
  }
  elsif($snp->{'STATUS'} == 3){
    $type = "Two-Hit";
  }
  push @features, {
		   'id'      => $snp->{'ID_DEFAULT'},
		   'type'    => $type,
		   'method'  => "snp",
		   'start'   => $snp->{'CHR_START'},
		   'end'     => $snp->{'CHR_END'},
		   'ori'     => "0",
		   'link'    => $link,
		   'linktxt' => $self->{'linktxt'},
		   'typecategory' => "snp",
		  };
}
  return @features;
}

1;
