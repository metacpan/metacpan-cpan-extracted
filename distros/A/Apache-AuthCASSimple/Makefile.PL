use inc::Module::Install;
use Apache::src;

name            'Apache-AuthCASSimple';
perl_version '5.006';
all_from        'lib/Apache/AuthCASSimple.pm';

version_from 'lib/Apache/AuthCASSimple.pm';

requires 'mod_perl' => 1.0;
requires 'Apache::Session::Wrapper';
requires 'DynaLoader';
requires 'Authen::CAS::Client';

my $apache = Apache::src->new;

inc     $apache->inc();

build_requires  'mod_perl' => 1.0;
build_requires  'Apache::src';
build_requires  'Pod::Coverage';
build_requires  'Test::More';

auto_install;

install_script('scripts/delete_session_data.pl');

tests('t/*.t');

WriteAll;

