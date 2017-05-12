use inc::Module::Install 0.46;

name('Asterisk-FastAGI');
license('perl');
perl_version('5.006');
version_from('lib/Asterisk/FastAGI.pm');

requires('Asterisk::AGI');
requires('Net::Server::PreFork');

no_index directory => 't';
no_index package => 'inc';

WriteAll;
