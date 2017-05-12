# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Multiscript.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('CGI::Multiscript') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

CGI::Multiscript::setDefault("./");
CGI::Multiscript::setDefault("sh ");
print "Default execution ", CGI::Multiscript::getDefault(), "\n";
$ms = CGI::Multiscript::new('test_hello.ms');
$ms->addLanguage('perl');
$ms->addLanguage('python');
$ms->parseArgs(@ARGV);
$ms->displayLangs();
print "Current filename ", $ms->getFilename(), "\n";

$ms->setFilename("t/test_hello.ms");
$ms->execute();

