#########
# Author:        rmp
# Last Modified: $Date: 2010-09-22 17:47:07 +0100 (Wed, 22 Sep 2010) $ $Author: andyjenkinson $
# Id:            $Id: 05-singledsn.t 43 2010-09-22 16:47:07Z andyjenkinson $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/05-singledsn.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/05-singledsn.t $
#
package singledsn;
use strict;
use warnings;
use Test::More tests => 33;
use Bio::Das::Lite;

our $VERSION = do { my @r = (q$Revision: 43 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

$Bio::Das::Lite::DEBUG = 0;

for my $service ('http://das.sanger.ac.uk/das',
		 'http://das.ensembl.org/das/dsn',
		 'http://das.ensembl.org/das/dsn#foo') {

  #########
  # test single dsn from constructor
  #
  my $das     = Bio::Das::Lite->new({'dsn' => $service, 'timeout' => 10});
  ok(defined $das,                  'new with a single dsn returned something');
  ok(ref($das->dsn()) eq 'ARRAY',   'single service get gave an array ref');
  ok(scalar (@{$das->dsn()}) == 1,  'single service get had length of one');
  ok($das->dsn->[0] eq $service,    'single service get returned the same dsn');

  my $dsns = $das->dsns();
  ok(defined $dsns,                 "dsns call returned something (service $service)");
  ok(ref($dsns) eq 'HASH',          "dsns call gave a hash (service $service)");
  my @keys = keys %{$dsns};
  ok(scalar @keys == 1,             "dsns call gave one key service $service)");
  my $key = $keys[0];
  my $code = $das->statuscodes($key);
  ok($code =~ /^200/,               "dsns call returned OK status (service $service status $code)");
  ok($dsns->{$key} && ref($dsns->{$key}) eq 'ARRAY', "dsns call gave a arrayref value (service $service)");
  my @sources = @{$dsns->{$key} || []};
  ok(scalar @sources > 0,           "dsns call returned at least one source (service $service)");
  my @broken = grep { ref($_) ne 'HASH' } @sources;
  ok(scalar @broken == 0,           "all sources parsed correctly into hashes (service $service)");
}

1;
