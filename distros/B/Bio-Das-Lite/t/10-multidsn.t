#########
# Author:        rmp
# Last Modified: $Date: 2010-09-22 17:47:07 +0100 (Wed, 22 Sep 2010) $ $Author: andyjenkinson $
# Id:            $Id: 10-multidsn.t 43 2010-09-22 16:47:07Z andyjenkinson $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/10-multidsn.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/10-multidsn.t $
#
package multidsn;
use strict;
use warnings;
use Test::More tests => 11;
use Bio::Das::Lite;

our $VERSION = do { my @r = (q$Revision: 43 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
my @services = qw(http://das.ensembl.org/das/dsn http://das.sanger.ac.uk);
my $das      = Bio::Das::Lite->new({'dsn' => \@services, 'timeout' => 10});

ok(defined $das,                  'new with a multi dsn returned something');
ok(ref($das->dsn()) eq 'ARRAY',   'multi service get gave an array ref');
ok(scalar (@{$das->dsn()}) == 2,  'multi service get had length of one');
ok($das->dsn->[0] eq $services[0] &&
   $das->dsn->[1] eq $services[1],    'multi service get returned the same dsns in the same order');

my $dsns = $das->dsns();
ok(defined $dsns,                 'dsns call returned something');
ok(ref $dsns eq 'HASH',           'dsns call gave a hash');

my @keys = keys %{$dsns};
ok(scalar @keys == 1,             'dsns call gave one key');

my $key = $keys[0];

my $code = $das->statuscodes($key);
ok($code =~ /^200/,               "dsns call returned OK status (status is $code)");

ok(ref $dsns->{$key} eq 'ARRAY', 'dsns call gave a arrayref value for the one key');

my @sources = @{$dsns->{$key}};
ok(scalar @sources > 0,           'dsns call returned at least one source');

my @broken = grep { ref $_ ne 'HASH' } @sources;
ok(scalar @broken == 0,           'all sources parsed correctly into hashes');

1;
