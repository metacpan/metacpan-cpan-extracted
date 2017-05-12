#########
# Author: jc3
# Maintainer: jc3
# Created: 2003-09-17
# Last Modified: 2003-09-17
# Provides DAS features for Haplotype Information.

package Bio::Das::ProServer::SourceAdaptor::haplotype;

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
  $self->{'link'} = "http://intweb.sanger.ac.uk/cgi-bin/humace/snp_report.pl?block=";
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
		       <CATEGORY id="haplotype">
		        <TYPE id="Hap African American">
		         <GLYPH>
		          <BOX>
		           <FGCOLOR>blue4</FGCOLOR>
                           <FONT>sanserif</FONT>
		           <BGCOLOR>black</BGCOLOR>
		          </BOX>
		         </GLYPH>
		        </TYPE>
		        <TYPE id="Hap Cauc Unrelateds">
		         <GLYPH>
		          <BOX>
		           <FGCOLOR>blueviolet</FGCOLOR>
                           <FONT>sanserif</FONT>
		           <BGCOLOR>black</BGCOLOR>
		          </BOX>
		         </GLYPH>
		        </TYPE>
		        <TYPE id="Hap Asians">
		         <GLYPH>
		          <BOX>
		           <FGCOLOR>darkslateblue</FGCOLOR>
                           <FONT>sanserif</FONT>
		           <BGCOLOR>black</BGCOLOR>
		          </BOX>
		         </GLYPH>
		        </TYPE>
		        <TYPE id="Hap CEPH family">
		         <GLYPH>
		          <BOX>
		           <FGCOLOR>lightblue3</FGCOLOR>
                           <FONT>sanserif</FONT>
		           <BGCOLOR>black</BGCOLOR>
		          </BOX>
		         </GLYPH>
		        </TYPE>
		        <TYPE id="default">
		         <GLYPH>
		          <BOX>
		           <FGCOLOR>red</FGCOLOR>
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
  my $segid     = $opts->{'segment'};
  my $start     = $opts->{'start'};
  my $end       = $opts->{'end'};
  my $assm_name = $self->config->{'assm_name'};
  my $assm_ver  = $self->config->{'assm_ver'};

  my @features = ();
  if (!$end || $segid !~ /^(10|20|(1?[1-9])|(2?[12])|[XY])$/i){
    return @features;
  }

 my  $query = qq( SELECT
                ms.position + ssm.start_coordinate - 1
                                    as start_coord,
                ms.end_position + ssm.start_coordinate - 1
                                    as end_coord,
                ms.id_snp           as id_snp,
                sb.id_block         as block,
                b.length            as block_length,
                b.num_snps          as num_snps,
                p.description       as population,
                p.id_pop            as id_pop,
                ssum.is_private     as private_snp,
                bs.is_private       as private_block,
                bs.maf              as maf
        FROM    chrom_seq cs,
                database_dict dd,
                seq_seq_map ssm,
                mapped_snp ms,
                snp_summary ssum,
                snp_block sb,
                block b,
                block_set bs,
                population p
        WHERE   cs.database_seqname = '$segid'
        AND     dd.database_name = '$assm_name'
        AND     dd.database_version = '$assm_ver'
        AND     dd.id_dict = cs.database_source
        AND     ssm.id_chromseq = cs.id_chromseq
        AND     ms.id_sequence = ssm.sub_sequence
        AND     ssum.id_snp = ms.id_snp
        AND     ssum.id_snp = sb.id_snp
        AND     sb.id_block = b.id_block
        AND     b.id_block_set = bs.id_block_set
        AND     bs.id_pop = p.id_pop
        AND     ms.position
                BETWEEN
                ($start - ssm.start_coordinate - 99)
                AND
                ($end - ssm.start_coordinate + 1)
        ORDER BY
                start_coord
);


my $haplotype = $self->transport->query($query);

  for my $haplotype (@$haplotype){
    my $url = $self->{'link'};
    my $link = $url . $haplotype->{'BLOCK'};

    push @features, {
		     'type'    => $haplotype->{'POPULATION'},
		     'id'      => $haplotype->{'BLOCK'},
		     #'group'   => $haplotype->{'BLOCK_SET'},
		     'method'  => "haplotype",
		     'start'   => $haplotype->{'START_COORD'},
		     'end'     => $haplotype->{'END_COORD'},
		     'link'    => $link,
		     'linktxt' => $self->{'linktxt'},
		     'typecategory' => "haplotype",
		     'note'    => qq(MAF: $haplotype->{'MAF'}),
		    };
  }
  return @features;
}
1;
