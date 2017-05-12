use inc::Module::Install;

name     'App-Cmd-Starter';
all_from 'lib/Module/Starter/Plugin/App/Cmd.pm';
author   q{Jon Allen (JJ) <jj@jonallen.info>};
license  'perl';

build_requires 'Test::More';

requires 'Class::Monkey';
requires 'Module::Starter::Simple';

resources(
        'repository', => {
            web => 'https://github.com/jonallen/App-Cmd-Starter',
            url => 'git://github.com/jonallen/App-Cmd-Starter.git',
            type => 'git',
        },
);

install_script 'script/appcmd-starter';

auto_install;

WriteAll;

