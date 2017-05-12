use Test::More tests => 2;
use Acme::Perl::Consensual;

cmp_ok(Acme::Perl::Consensual->new->age_of_perl('2.000'), '>', 20);
cmp_ok(Acme::Perl::Consensual->new->age_of_perl('5.16'),  '<', 16);
