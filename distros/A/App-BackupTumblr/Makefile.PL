use inc::Module::Install;

name     'App-BackupTumblr';
all_from 'lib/App/BackupTumblr.pm';
author   q{Leonardo Kim <dalinaum@gmail.com>};
license  'perl';

repository 'git://github.com/dalinaum/App-BackupTumblr.git';

requires 'JSON';
requires 'WWW::Tumblr';
build_requires 'Test::More';

system('pod2text lib/App/BackupTumblr.pm > README');
auto_install;
install_script 'bin/BackupTumblr';
WriteAll;

