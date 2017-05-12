#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-12-03
# Last Modified: 2003-12-03
# Serve mpacked thumbnail images from mysql blobs
#
package Bio::Das::ProServer::SourceAdaptor::image;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use vars qw(@ISA);
use MIME::Base64;
use Bio::Das::ProServer::SourceAdaptor;
@ISA = qw(Bio::Das::ProServer::SourceAdaptor);

sub init {
  my $self                = shift;
  $self->{'capabilities'} = {
			     'features' => '1.0',
			    };
}

sub length {
    0;
}

sub build_features {
  my ($self, $opts) = @_;
  my $qsegment      = $self->transport->dbh->quote($opts->{'segment'});
  my $query         = qq(SELECT id,link,thumbnail AS note
			 FROM   proserver_imagesource
			 WHERE  id = $qsegment);
  return map {
    if($_->{'note'}) {
      $_->{'note'} = encode_base64($_->{'note'});
    }
    $_->{'type'}   = "image";
    $_->{'method'} = "image";
    $_;
  } @{$self->transport->query($query)};
}

1;
