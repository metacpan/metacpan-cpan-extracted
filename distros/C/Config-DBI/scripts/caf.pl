use Config::ApacheFormat;
use Data::Dumper;

my $c = Config::ApacheFormat->new();
$c->read('../system.conf');

my %ret = $c->get('attr');

warn Dumper(\%ret);
