#########
# Author:        rmp
# Last Modified: $Date: 2010-03-24 19:29:46 +0000 (Wed, 24 Mar 2010) $ $Author: zerojinx $
# Id:            $Id: FileStub.pm 19 2010-03-24 19:29:46Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/FileStub.pm,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/FileStub.pm $
#
package t::FileStub;
use base qw(Bio::Das::Lite);
use strict;
use warnings;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 19 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};

  my $self = $class->SUPER::new($ref);

  $self->{'filedata'} = $ref->{'filedata'};
  return $self;
}

sub _fetch {
  my ($self, $url_ref, $headers) = @_;

  open my $fh, q(<), $self->{'filedata'} or die "Cannot open $self->{'filedata'}:[$ERRNO]\n";
  local $RS = undef;
  my $xml  = <$fh>;
  close $fh;

  for my $code_ref (values %{$url_ref}) {
    &{$code_ref}($xml);
  }
  return;
}

1;
