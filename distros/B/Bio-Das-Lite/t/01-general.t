#########
# Author:        rmp
# Last Modified: $Date: 2010-11-02 09:50:49 +0000 (Tue, 02 Nov 2010) $ $Author: andyjenkinson $
# Id:            $Id: 01-general.t 45 2010-11-02 09:50:49Z andyjenkinson $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/01-general.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/01-general.t $
#
package general;
use strict;
use warnings;
use Test::More tests => 7;
use Bio::Das::Lite;

our $VERSION = do { my @r = (q$Revision: 45 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

{
  my $das = Bio::Das::Lite->new();
  isa_ok($das, 'Bio::Das::Lite');
}

{
  my $rnd = 1+int rand 60;
  is(Bio::Das::Lite->new({'timeout'    => $rnd})->timeout(),      $rnd,   'get/set timeout');
  my $proxy = 'http://webcache.localnet:3128/';
  is(Bio::Das::Lite->new({'http_proxy' => $proxy})->http_proxy(), $proxy, 'get/set http_proxy');
}

{
  #########
  # test single http fetch (on a non-DAS page!)
  #
  my $str  = q();
  my $urls = {
	      'http://search.cpan.org/~rpettett/Bio-Das-Lite/' => sub { $str .= $_[0]; return; }
	     };
  my $das  = Bio::Das::Lite->new();
  $das->_fetch($urls);
  ok($str =~ m|<html.*/html>|smix, 'plain http fetch');
}

{
  my $das      = Bio::Das::Lite->new({
				    'dsn'     => 'http://www.ebi.ac.uk/das-srv/genomicdas/das/cytochip3_36',
				    'timeout' => 30,
				   });
  my $f_by_id  = $das->features({'feature_id' => 'RP11-484P7'});
  ok(ref($f_by_id) eq 'HASH',      'feature-by-id returned a list');

  my $key      = (keys %{$f_by_id})[0];

  ok(scalar @{$f_by_id->{$key}||[]} <= 1,      'feature-by=id returned one or no elements');
  ok(ref($f_by_id->{$key}->[0]) eq 'HASH', 'feature-by-id element was a hash');
}

1;
