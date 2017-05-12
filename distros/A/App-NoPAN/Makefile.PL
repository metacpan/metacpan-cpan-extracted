use inc::Module::Install;

name 'App-NoPAN';
all_from 'nopan';
readme_from 'nopan';

requires 'Pod::Usage';
requires 'HTML::LinkExtor';
requires 'LWP::Simple';
requires 'Scope::Guard';
requires 'URI::Escape';

# for Installer::Perl
requires 'Archive::Tar';
requires 'CPAN::Inject';
requires 'Path::Class';

test_requires 'File::Slurp';
test_requires 'Test::More' => 0.88;

install_script 'nopan';

auto_include;
auto_install;

WriteAll;
