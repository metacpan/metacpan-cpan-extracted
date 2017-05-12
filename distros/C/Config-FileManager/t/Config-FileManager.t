# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Config-FileManager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN {
  use_ok('Config::FileManager')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Spec;
use File::Basename;

my $prog = basename("$0", ".t");
my $dirname = dirname(File::Spec->rel2abs(__FILE__));

my $cfg = new Config::FileManager(
                                  "toolname" => "test1",
                                  "interactive" => 0,
                                  "paths" => ["/tmp"],
                                 );

$cfg->addPatch(
	       "from"  => "0.0.1",
	       "to"    => "0.0.0",
	       "diffs" => '
@@ -1,2 +0,0 @@
-# Default configuration file __VERSION__
-# blablabla
');

$cfg->addPatch(
	       "from"  => "0.1.0",
	       "to"    => "0.0.1",
	       "diffs" => '
@@ -1,5 +1,2 @@
 # Default configuration file __VERSION__
-# Param_1 Value_1
-# Param_2 Value_2
-# Param_3 Value_3
-# Param_4 Value_4
+# blablabla
');

$cfg->addPatch(
	       "from"  => "0.1.1",
	       "to"    => "0.1.0",
	       "diffs" => '
@@ -1,7 +1,5 @@
 # Default configuration file __VERSION__
 # Param_1 Value_1
-Param_1 Value_1
 # Param_2 Value_2
-Param_2 Value_2
 # Param_3 Value_3
 # Param_4 Value_4
');

$cfg->version('0.1.1');
$cfg->defaultContent('
# Default configuration file __VERSION__
# Param_1 Value_1
Param_1 Value_1
# Param_2 Value_2
Param_2 Value_2
# Param_3 Value_3
# Param_4 Value_4
');


print "*** Current default config is:\n".$cfg->getDefaultContent()."*** End of file ***\n\n";

foreach my $v ($cfg->versions) {
  print "Content of config file for ".$cfg->toolname." [".$cfg->getPath."]:\n";
  print "*** Default config v. $v is:\n".$cfg->getDefaultContent($v)."*** End of file ***\n\n";
}

$cfg->addPatch(
	       "from"  => "1.0.0",
	       "to"    => "0.1.1",
	       "diffs" => '
@@ -1,2 +0,0 @@
 # Default configuration file __VERSION__
-# This is a new version
-# Just to test the update method 
 # Param_1 Value_1
');

$cfg->version('1.0.0');
$cfg->defaultContent('
# Default configuration file __VERSION__
# This is a new version
# Just to test the update method 
# Param_1 Value_1
Param_1 Value_1
# Param_2 Value_2
Param_2 Value_2
# Param_3 Value_3
# Param_4 Value_4
');

print "*** Previous default config was:\n".$cfg->getDefaultContent("0.1.1")."*** End of file ***\n\n";

print "*** Current default config is now:\n".$cfg->getDefaultContent()."*** End of file ***\n\n";

$cfg->update;

print "\n*** Removing test1 config file [".$cfg->getPath."] ***\n";


my $v = $cfg->getPath;
unlink $v;

print "Ok\n";
#$cfg->filename("test2");

1;
