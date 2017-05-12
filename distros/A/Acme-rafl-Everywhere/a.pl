use Acme::rafl::Everywhere;

my $fact_bag = Acme::rafl::Everywhere->new;
my $fact = $fact_bag->fact;
use DDP;
p $fact;
