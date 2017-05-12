use strict;
use warnings;
use inc::Module::Install 0.91;

BEGIN {
    if ($Module::Install::AUTHOR) {
        require Module::Install::AuthorTests;
    }
}

name 'Catalyst-TraitFor-Request-ProxyBase';
all_from 'lib/Catalyst/TraitFor/Request/ProxyBase.pm';

requires 'URI';
requires 'Moose';
requires 'namespace::autoclean';

test_requires 'Catalyst::Runtime' => '5.80007';
test_requires 'CatalystX::RoleApplicator' => '0.005';
test_requires 'Test::More' => '0.88';
test_requires 'HTTP::Request::Common';

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-TraitFor-Request-ProxyBase';
license 'perl';

author_tests('t/author');

WriteAll();

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/TraitFor/Request/ProxyBase.pm > README")
        and die;
}

