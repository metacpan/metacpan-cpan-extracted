# $Id: 01-key.t 32 2008-08-25 17:18:34Z johntrammell $
# $URL: https://algorithm-voting.googlecode.com/svn/trunk/t/sortition/01-key.t $

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Digest::MD5 'md5_hex';

my $avs = 'Algorithm::Voting::Sortition';

use_ok($avs);

# verify that we can generate custom sequences by overrriding digest()
{
    no warnings qw/ once redefine /;
    local *Algorithm::Voting::Sortition::digest = sub { return "ffff"; };
    local *Algorithm::Voting::Sortition::n      = sub { return 5 };
    my $s = $avs->new(candidates => ['a'..'e']);
    is_deeply( [ $s->seq ], [ (0xffff) x 5 ] );
}

# verify that non-hex digests raise an exception
{
    no warnings qw/ once redefine /;
    local *Algorithm::Voting::Sortition::digest = sub { return "zzzz"; };
    local *Algorithm::Voting::Sortition::n      = sub { return 5 };
    my $s = $avs->new(candidates => ['a'..'e']);
    my @seq;
    throws_ok { @seq = $s->seq } qr/invalid hex/, "invalid hex raises exception";
    warn "@seq";
}

