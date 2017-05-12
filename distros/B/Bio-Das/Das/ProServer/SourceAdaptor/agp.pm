#########
# Author: avc, rmp
# Maintainer: rmp
# Last Modified: 2003-06-13
# AGP adaptor paired with ProServer::Loader::agp
#
package Bio::Das::ProServer::SourceAdaptor::agp;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Based on AGPServer by

Tony Cox <avc@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Bio::Das::ProServer::SourceAdaptor;
use vars qw(@ISA $CLONE_STATUS);

@ISA = qw/Bio::Das::ProServer::SourceAdaptor/;
# F = Finished         = HTGS_PHASE3
# A = Almost finished  = HTGS_PHASE2 (Rare)
# U = Unfinished       = HTGS_PHASE1 (Not ususally in AGPs, but can be.)
# N = Gap in AGP - these lines have an optional qualifier (eg: CENTROMERE)
$CLONE_STATUS = {
		 'F' => "Finished/HTGS_PHASE3",
		 'A' => "Almost finished/HTGS_PHASE2",
		 'U' => "Unfinished/HTGS_PHASE1",
		 'N' => "Gap in AGP",
		 'D' => "",
		};

sub init {
  my $self                = shift;
  $self->{'capabilities'} = {
                             'features'      => '1.0',
			     'feature-by-id' => '1.0',
			     'entry_points'  => '1.0',
                            };
}

#########
# chromosome length form db
#
sub length {
  my ($self, $seg) = @_;

  unless($self->{'_length'}->{$seg}) {
    my $table = $self->config->{'tablename'};
    my $ref   = $self->transport->query(qq(SELECT MAX(chr_end) AS length
					   FROM   $table
					   WHERE chr='$seg'));
    if(scalar @$ref) {
      $self->{'_length'}->{$seg} = @{$ref}[0]->{'length'};
    }
  }
  return $self->{'_length'}->{$seg};
}


#########
# build entry points from db
#
sub build_entry_points {
  my $self  = shift;
  my $table = $self->config->{'tablename'};
  my $query = qq(SELECT chr AS segment, MAX(chr_end) AS length
                 FROM   $table
                 GROUP BY chr);
  return @{$self->transport->query($query)};
}


#########
# build features from db
#
sub build_features {
  my ($self, $opts) = @_;

  my $table   = $self->config->{'tablename'};
  my @qxtras  = ();
  push @qxtras, qq(chr       =  '$opts->{'segment'}')   if(defined $opts->{'segment'});
  push @qxtras, qq(chr_start <  '$opts->{'end'}')       if(defined $opts->{'start'} && defined $opts->{'end'});
  push @qxtras, qq(chr_end   >  '$opts->{'start'}')     if(defined $opts->{'start'} && defined $opts->{'end'});
  @qxtras     = qq(embl_id LIKE '%$opts->{'feature'}%') if(defined $opts->{'feature'});
  my $extra   = "WHERE " . join(' AND ', @qxtras)       if(scalar @qxtras > 0);
  my $query   = qq(SELECT type       AS status,
                          chr        AS segment,
                          embl_id    AS id,
                          embl_start AS target_start,
                          embl_end   AS target_stop,
                          chr_start  AS start,
                          chr_end    AS end,
                          embl_ori   AS ori
		   FROM   $table
                   $extra
		   ORDER by chr,chr_start);

  my $ref = $self->transport->query($query);

  for my $i (@{$ref}) {
    $i->{'note'}   = "clone_status:$i->{'status'}:" . $CLONE_STATUS->{$i->{'status'}};
    $i->{'type'}   = "static_golden_path";
    $i->{'method'} = "agp-clone";
    delete($i->{'status'});
  }

  return @{$ref};
}

1;
