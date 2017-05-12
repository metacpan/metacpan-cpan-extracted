use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 3;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->parse($fn);
my $schema = $stag->autoschema;
print $schema->sxpr;
ok($schema->find('gene+'));
ok($schema->find('map?'));
ok($schema->find('phenotype*'));
