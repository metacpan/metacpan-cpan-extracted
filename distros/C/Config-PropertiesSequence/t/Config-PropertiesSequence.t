# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Config-PropertiesSequence.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Config::PropertiesSequence') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $propertiesSequence = Config::PropertiesSequence->new();
$propertiesSequence->load( *DATA ) ;
my @props = $propertiesSequence->getPropertySequence( "test.settings.multi",qw(setting1 setting2) );
ok(@props,"get properties sequence");
ok($props[0]->{setting1} eq "abc","sample property");
ok($props[0]->{setting2} ne "defg","sample property");
ok($props[0]->{setting2} eq "def","sample property");
ok($props[1]->{setting1} ne "abc","sample property");
ok($props[1]->{setting1} eq "ghi","sample property");
ok($props[1]->{setting2} eq "jkl","sample property");
 
__DATA__
test.settings.multi.1.setting1=abc
test.settings.multi.1.setting2=def
test.settings.multi.2.setting1=ghi
test.settings.multi.2.setting2=jkl


