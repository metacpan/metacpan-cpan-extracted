#########
# Author:        rmp
# Last Modified: $Date: 2011-05-06 11:18:40 +0100 (Fri, 06 May 2011) $ $Author: zerojinx $
# Id:            $Id: 60-features_chunked.t 53 2011-05-06 10:18:40Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/60-features_chunked.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/60-features_chunked.t $
#
package features_chunked;
use strict;
use warnings;
use Test::More tests => 1;
use t::FileStubChunked;

our $VERSION = do { my @r = (q$Revision: 53 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

my $das      = t::FileStubChunked->new({
					'dsn'      => 'http://foo/das/bar',
					'filedata' => 't/data/features.xml',
				       });
my $features = $das->features();
my $results  = (values %{$features})[0];

is(scalar @{$results}, 102, 'Chunked-response-mode gave number of features returned');

1;
