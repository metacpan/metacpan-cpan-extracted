use t::Helper;

my $app = eval 'use Applify; app {0};' or die $@;
my $script = $app->_script;

eval { $script->print_version };
like $@, qr{Cannot print version}, 'cannot print version without version(...)';

eval { $script->version(undef) };
like $@, qr{Usage: version }, 'need to give version(...) a true value';
is $script->version('1.23'), $script, 'version(...) return $self';
is $script->version, '1.23', 'version() return what was set';

is + (run_method($script, 'print_version'))[0], "version.t version 1.23\n", 'print_version(numeric)';

$script->version('Applify');
is + (run_method($script, 'print_version'))[0], "version.t version $Applify::VERSION\n", 'print_version(module)';

done_testing;
