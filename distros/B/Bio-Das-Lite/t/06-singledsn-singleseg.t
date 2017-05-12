#########
# Author:        rmp
# Last Modified: $Date: 2011-05-06 11:18:40 +0100 (Fri, 06 May 2011) $ $Author: zerojinx $
# Id:            $Id: 06-singledsn-singleseg.t 53 2011-05-06 10:18:40Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/06-singledsn-singleseg.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/06-singledsn-singleseg.t $
#
package singledsn_singleseg;
use Test::More tests => 13;
use strict;
use warnings;
use t::FileStub;

our $VERSION = do { my @r = (q$Revision: 53 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

my $req = '10:1,1000';
my $das;
for my $call (qw(entry_points types features sequence)) {
  $das = t::FileStub->new({
			   'dsn'      => 'foo',
			   'filedata' => "t/data/${call}-ensembl1834.xml",
			  });
  my $res       = $das->$call($req);
  ok(ref$res eq 'HASH',                   "$call returns a hash");
  ok(scalar keys %{$res} == 1,            "$call returns the same number of sources");
  ok(ref((values %{$res})[0]) eq 'ARRAY', "$call hash contains an array");

  #########
  # check return codes
  #
  my $codes = $das->statuscodes();
  my $code  = 0;
  for my $u (keys %{$codes}) {
    if($u =~ /$call.*10:1,1000/mx) {
      $code = substr $codes->{$u}, 0, 3;
      last;
    }
  }
}

my $sequence = $das->sequence('1:1,1000');
my $key      = (keys %{$sequence})[0];
my $seq      = $sequence->{$key}->[0]->{'sequence'} || q();
$seq         =~ s/\s+//smgx;

is(length $seq, 1000, 'requesting 1Kb of sequence returns 1Kb');

1;
