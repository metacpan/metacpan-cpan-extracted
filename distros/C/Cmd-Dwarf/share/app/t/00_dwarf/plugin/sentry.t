use Dwarf::Pragma;
use Dwarf;
use Encode qw/decode_utf8/;
use Test::More;
use Test::Requires 'Sentry::Raven', 'Devel::StackTrace';

my $c = Dwarf->new();
my $dsn = $c->conf('/sentry/dsn');

$c->load_plugin(Sentry => { dsn => $dsn || 'dummy' });

ok $c->can('call_sentry');
$c->call_sentry('Hello, dwarf!') if $dsn;

done_testing;
