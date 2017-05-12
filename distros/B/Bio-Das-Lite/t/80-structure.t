#########
# Author:        rdf
# Last Modified: $Date: 2011-05-06 11:18:40 +0100 (Fri, 06 May 2011) $ $Author: zerojinx $
# Id:            $Id: 80-structure.t 53 2011-05-06 10:18:40Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/80-structure.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/80-structure.t $
#
package structure;
use strict;
use warnings;
use Test::More tests => 9;
use t::FileStub;

our $VERSION  = do { my @r = (q$Revision: 53 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

my $das       = t::FileStub->new({
				  'dsn'      => 'foo',
				  'filedata' => 't/data/structure.xml',
				 });
my $structure = $das->structure();
my $results   = (values %{$structure})[0];

#Total
is(scalar @{$results}, 1, 'Whole-response-mode gave correct structure');

#Chains
is(scalar @{$results->[0]->{chain}}, 1, 'Got the correct number of chains');
is(scalar @{$results->[0]->{chain}->[0]->{group}}, 3, 'Got the correct number of groups for the chain');
is(scalar @{$results->[0]->{chain}->[0]->{group}->[0]->{atom}}, 26,'Got the correct number of atoms for the first group');

#Het Stuff 
is(scalar @{$results->[0]->{het}}, 1, 'Got the correct number of het');
is(scalar @{$results->[0]->{het}->[0]->{group}}, 1, 'Got the correct number of groups for the het');
is(scalar @{$results->[0]->{het}->[0]->{group}->[0]->{atom}}, 1,'Got the correct number of atoms for the first group');

#Connection Stuff
is(scalar @{$results->[0]->{connect}}, 1, 'Got connection data');
is(scalar @{$results->[0]->{connect}->[0]->{atomID}}, 2, 'Got correct number of atoms in connection');

1;
