use inc::Module::Install;

name            'Apache2-AuthCASSimple';
perl_version    '5.008';
all_from        'lib/Apache2/AuthCASSimple.pm';
version_from        'lib/Apache2/AuthCASSimple.pm';

requires 'Apache::Session::Wrapper';
requires 'Authen::CAS::Client';
requires 'mod_perl2';
requires 'Crypt::SSLeay';
requires 'URI::Escape';

build_requires  'Pod::Coverage';
build_requires  'Test::More';
build_requires 'Apache::Session::Wrapper';
build_requires 'Authen::CAS::Client';
build_requires 'URI::Escape';
build_requires 'mod_perl2';

auto_install;

no_index directory => 'examples';
#install_script('scripts/delete_session_data.pl');

tests('t/*.t');

WriteAll;

