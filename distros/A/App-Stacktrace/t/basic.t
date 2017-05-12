use Test::More tests => 1;
use Data::Dumper;
use Config;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Varname = 'config';
$Data::Dumper::Terse = 1;
diag(Dumper(\%Config));

require App::Stacktrace;
$Data::Dumper::Varname = 'perl_offsets';
diag(Dumper(App::Stacktrace::_perl_offsets()));

pass('Loaded ok');
