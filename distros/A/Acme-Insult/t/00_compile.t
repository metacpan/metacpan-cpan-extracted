use Test2::V0;
use open qw[:std :encoding(UTF-8)];
#
use lib '../lib', 'lib';
use Acme::Insult qw[:all];
#
imported_ok qw[insult flavors];
#
ok my @flavors = flavors(), 'flavors() returns a list';
{
    my $TODO = todo 'play it safe just in case we randomly pull pirate while it is down';
    ok insult(), 'insult()';
}
subtest 'flavors' => sub {
    my $TODO = todo 'some backends (::Pirate) are running on mouse wheels or something and tip over often';
    ok insult($_), 'insult(' . $_ . ')' for sort @flavors;
};
#
done_testing;
