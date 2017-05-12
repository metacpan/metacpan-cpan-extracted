use Test::More tests => 10;
use Acme::Perl::Consensual;

my $gb = Acme::Perl::Consensual->new(locale => 'gb');

ok(not $gb->can(age =>  6));
ok(    $gb->can(age => 16));
ok(    $gb->can(age => 26));
ok(    $gb->can(age => 26, married => 0));
ok(    $gb->can(age => 26, married => 1));

my $bo = Acme::Perl::Consensual->new(locale => 'tn_BO.UTF-8');
ok(not defined $bo->can(age => 16));
ok(not defined $bo->can(age => 26));
ok(            $bo->can(age => 12, puberty => 1));
ok(not         $bo->can(age => 12, puberty => 0));

ok($bo->can('locale'));
