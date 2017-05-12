use inc::Module::Install 0.87;

name('Catalyst-Authentication-Store-LDAP');
abstract('Authenticate Users against LDAP Directories');
author('Adam Jacob <holoway@cpan.org>');
version_from('lib/Catalyst/Authentication/Store/LDAP.pm');
license('perl');

requires('Net::LDAP');
requires( 'Catalyst::Plugin::Authentication' => '0.10003' );

#requires('Catalyst::Model::LDAP');
build_requires('Net::LDAP::Server::Test' => '0.07');
build_requires('Test::More', '0.88');
build_requires('Test::MockObject');
build_requires('Test::Exception');

resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-Authentication-Store-LDAP.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Authentication/Store/LDAP.pm > README")
        and die $!;
}

WriteAll;

