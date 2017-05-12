use inc::Module::Install;

name 'CatalystX-Plugin-Blurb';
license 'perl';
all_from 'lib/CatalystX/Plugin/Blurb.pm';
repository "git://github.com/pangyre/p5-catalystx-plugin-blurb";

requires 'Catalyst::Runtime';
requires 'parent';

test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Test::More';
test_requires 'ok';
test_requires "Catalyst::Plugin::Session";
test_requires "Catalyst::Plugin::Session::Store::FastMmap";
test_requires "Catalyst::Plugin::Session::State::Cookie";

WriteAll();

if ( $Module::Install::AUTHOR )
{
    system("pod2text lib/CatalystX/Plugin/Blurb.pm > README") == 0
        or die "Couldn't update the README";
}
