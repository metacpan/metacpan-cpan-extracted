# $Id$
# $URL$

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

my $avs = 'Algorithm::Voting::Sortition';
use_ok($avs);

# verify that A::V::S generates the same keystring as in
# L<http://tools.ietf.org/html/rfc3797#section-6>
{
    my @source = (
        "9319",
        [ qw/ 2 5 12 8 10 / ],      # <= this one gets sorted
        [ qw/ 9 18 26 34 41 45 /],
    );
    my $ks = q(9319./2.5.8.10.12./9.18.26.34.41.45./);
    is ($avs->make_keystring(@source), $ks);
}

# verify that A::V::S generates checksums identical to
# L<http://tools.ietf.org/html/rfc3797#section-6>
{
    my $ks = q(9319./2.5.8.10.12./9.18.26.34.41.45./);
    my $box = Algorithm::Voting::Sortition->new(candidates => [], n => 10, keystring => $ks);
    is($box->n, 10);
    is($box->keystring, $ks);

    # the first string is the digest of the keystring bracketed by the string
    # "\x00\x00", the next "\x00\x01", and so on.

    my @rfc_digests = split(/\n/,<<__digests__);
990DD0A5692A029A98B5E01AA28F3459
3691E55CB63FCC37914430B2F70B5EC6
FE814EDF564C190AC1D25753979990FA
1863CCACEB568C31D7DDBDF1D4E91387
F4AB33DF4889F0AF29C513905BE1D758
13EAEB529F61ACFB9A29D0BA3A60DE4A
992DB77C382CA2BDB9727001F3CDCCD9
63AB4258ECA922976811C7F55C383CE7
DFBC5AC97CED01B3A6E348E3CC63F40D
31CB111C4A4EBE9287CEAE16FE51B909
07FA46C122F164C215BBC72793B189A3
AC52F8D75CCBE2E61AFEB3387637D501
53306F73E14FC0B2FBF434218D25948E
B5D1403501A81F9A47318BE7893B347C
85B10B356AA06663EF1B1B407765100A
3269E6CE559ABD57E2BA6AAB495EB9BD
__digests__

    for my $i (0 .. $#rfc_digests) {
        is(lc($box->digest($i)),lc($rfc_digests[$i]));
    }

}

# recreate the RFC3797 example result set
{

# candidates are:
#     1. John         11. Pollyanna       21. Pride
#     2. Mary         12. Pendragon       22. Sloth
#     3. Bashful      13. Pandora         23. Envy
#     4. Dopey        14. Faith           24. Anger
#     5. Sleepy       15. Hope            25. Kasczynski
#     6. Grouchy      16. Charity
#     7. Doc          17. Lee
#     8. Sneazy       18. Longsuffering
#     9. Handsome     19. Chastity
#    10. Cassandra    20. Smith

    my @c = qw/
        John Mary Bashful Dopey Sleepy
        Grouchy Doc Sneazy Handsome Cassandra
        Pollyanna Pendragon Pandora Faith Hope
        Charity Lee Longsuffering Chastity Smith
        Pride Sloth Envy Anger Kasczynski
        /;

    my $keystring = q(9319./2.5.8.10.12./9.18.26.34.41.45./);

    # choose 10 winners from the candidate pool
    my $box = Algorithm::Voting::Sortition->new(
        candidates => \@c,
        n          => 10,
        keystring  => $keystring
    );

    # make sure *our* result is the same as the RFC
    my @rfc_result = qw(
        Lee Doc Mary Charity Kasczynski
        Envy Sneazy Anger Chastity Pandora
    );

    is_deeply([$box->result], \@rfc_result) or
        diag(Dumper([$box->result]));

    my $s = $box->as_string;
    like($s, qr/1. Lee/);
    like($s, qr/3. Mary/);
    like($s, qr/5. Kasczynski/);
    like($s, qr/7. Sneazy/);

}
