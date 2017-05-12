use inc::Module::Install;

name 'Catalyst-Authentication-Credential-OAuth';
all_from 'lib/Catalyst/Authentication/Credential/OAuth.pm';

requires 'Moose';
requires 'Net::OAuth';
requires 'LWP::UserAgent';
requires 'String::Random';
requires 'MooseX::Types::Common::String';
requires 'MooseX::Types';
requires 'namespace::autoclean';

test_requires 'Catalyst::Runtime';
test_requires 'Test::More';

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-Authentication-Credential-OAuth.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Authentication/Credential/OAuth.pm > README")
        and die;
}

WriteAll();

