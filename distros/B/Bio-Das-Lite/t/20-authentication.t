#########
# Author:        rmp
# Last Modified: $Date: 2010-03-24 19:29:46 +0000 (Wed, 24 Mar 2010) $ $Author: zerojinx $
# Id:            $Id: 20-authentication.t 19 2010-03-24 19:29:46Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/20-authentication.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/20-authentication.t $
#
package compat_multidsn;
use strict;
use warnings;
use Test::More tests => 3;
use Bio::Das::Lite;

our $VERSION = do { my @r = (q$Revision: 19 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

my $das = Bio::Das::Lite->new({
			       'http_proxy' => 'https://foo:bar@webcache.example.com:3128/',
			      });

is($das->http_proxy(), 'https://webcache.example.com:3128/', 'http_proxy processed ok');
is($das->proxy_user(), 'foo', 'proxy_user processed ok');
is($das->proxy_pass(), 'bar', 'proxy_pass processed ok');

1;
