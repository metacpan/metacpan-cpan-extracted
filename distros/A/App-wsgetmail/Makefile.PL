use lib qw(.);
use Config;
use inc::Module::Install;
readme_from 'lib/App/wsgetmail.pm', 0, 'md';
all_from 'lib/App/wsgetmail.pm';
license 'gpl_2';

perl_version '5.010';

requires 'Azure::AD::ClientCredentials';
requires 'Clone';
requires 'FindBin';
requires 'File::Slurp';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'IPC::Run';
requires 'JSON';
requires 'LWP::UserAgent' => '6.42';
requires 'Module::Load';
requires 'Moo';
requires 'Pod::Usage';
requires 'strict';
requires 'Test::LWP::UserAgent';
requires 'Test::More';
requires 'URI::Escape';
requires 'URI';
requires 'warnings';

my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS' and $secure_perl_path !~ /$Config{_exe}$/i) {
    $secure_perl_path .= $Config{_exe};
}

substitute(
    {
        PERL => $ENV{PERL} || $secure_perl_path,
    },
    'bin/wsgetmail',
);

install_script('bin/wsgetmail');
auto_install();
sign;
WriteAll;
