#########
# Author:        rmp
# Last Modified: $Date: 2010-03-24 19:29:46 +0000 (Wed, 24 Mar 2010) $ $Author: zerojinx $
# Id:            $Id: FileStubChunked.pm 19 2010-03-24 19:29:46Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/FileStubChunked.pm,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/FileStubChunked.pm $
#
package t::FileStubChunked;
use strict;
use warnings;
use base qw(t::FileStub);

our $VERSION = do { my @r = (q$Revision: 19 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub _fetch {
  my ($self, $url_ref, $headers) = @_;

  open my $fh, q(<), $self->{'filedata'};
  while(my $xml = <$fh>) {
    for my $code_ref (values %{$url_ref}) {
      &{$code_ref}($xml);
    }
  }
  close $fh;
  return;
}

1;
