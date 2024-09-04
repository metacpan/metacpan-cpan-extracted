use Test2::V0;
use open qw[:std :encoding(UTF-8)];
use experimental 'for_list';
#
use lib '../lib', 'lib';
use Acme::Insult::Pirate qw[:all];
#
imported_ok qw[insult];
#
my $insult = insult();
#
{
    my $TODO = todo 'the pirate back end is way too fragile' unless +$insult;
    ok + $insult, 'stringify';
    #
    is my $insult = Acme::Insult::Pirate::insult(), hash {
        field insult => D();
    }, 'hash (fake)';
    isa_ok $insult, ['Acme::Insult::Pirate'], 'insults are blessed hashes';
};
#
done_testing;
