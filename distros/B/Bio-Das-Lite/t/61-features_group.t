#########
# Author:        rmp
# Last Modified: $Date: 2011-05-06 11:18:40 +0100 (Fri, 06 May 2011) $ $Author: zerojinx $
# Id:            $Id: 61-features_group.t 53 2011-05-06 10:18:40Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/61-features_group.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/61-features_group.t $
#
package features_group;
use strict;
use warnings;
use Test::More tests => 5;
use t::FileStub;

our $VERSION = do { my @r = (q$Revision: 53 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

my $das      = t::FileStub->new({
				 'dsn'      => 'foo',
				 'filedata' => 't/data/features-group.xml',
				});
my $features = $das->features();
my $results  = (values %{$features})[0];
my %features = map { $_->{'feature_id'} => $_ } @{ $results };

my $first_feature = $features{'id'};
my $parent_id = $first_feature->{'parent'}->[0]->{'parent_id'};
my $first_feature_group_data = $features{$parent_id};
is(scalar @{$first_feature_group_data->{'link'}},      2,                     'Corrent number of links returned');
is(scalar @{$first_feature_group_data->{'note'}},      2,                     'Corrent number of notes returned');
is($first_feature_group_data->{'link'}->[1]->{'href'}, 'groupurl2',           'Correct link href');
is($first_feature_group_data->{'link'}->[1]->{'txt'},  ' group link text 2',  'Correct link text');
is($first_feature_group_data->{'note'}->[1],           ' group note 2 text ', 'Correct note text');

1;
