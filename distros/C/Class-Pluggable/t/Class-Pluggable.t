#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;

######################## APlugin
package APlugin;

use vars qw(@EXPORT_AS_PLUGIN);

@EXPORT_AS_PLUGIN = qw(&foo &bar &hoge &getHookCounter);

my $hook_counter = 0;
sub foo { return "foo"; }
sub bar { return "bar"; }
sub hoge { return "hoge"; }

sub beforeAction {
  return "Plugin::APlugin::beforeAction";
}

sub afterAction {
  return "Plugin::APlugin::afterAction";
}

sub sampleHook {
  return ++$hook_counter;
}

sub getHookCounter {
  return $hook_counter;
}


######################### SamplePluggable
package SamplePluggable;

use Class::Pluggable;
use base qw(Class::Pluggable);

sub new {
  return bless {}, shift;
}

sub hello {
  return "hello";
}

######################### main
package main;

BEGIN { use_ok('Class::Pluggable') };
#use APlugin;
#use SamplePluggable;


# Two of SamplePluggable instance shouldn't effect each other.
my $sample = new SamplePluggable();
my $sample2 = new SamplePluggable();


# These are only for checking the effectivity between $sample
# and $sample2.
$sample2->add_plugin("APlugin");
$sample2->add_plugin("BPlugin");

is (scalar($sample->get_plugins()), 0, "initial size of plugins");

$sample->add_plugin("APlugin");
#SamplePluggable->add_plugin("APlugin");

is (scalar $sample->get_plugins(), 1, "final size of plugins");

can_ok ($sample, qw(foo bar hoge));

is ("hello", $sample->hello(), 'original method');
is ("foo",   $sample->foo(),   'plugged method(foo)');
is ("bar",   $sample->bar(),   'plugged method(bar)');
is ("hoge",  $sample->hoge(),  'plugged method(hoge)');

is ("Plugin::APlugin::beforeAction",
    $sample->execute_plugin_method("APlugin", "beforeAction"), "hook test");
is ("Plugin::APlugin::afterAction",
    $sample->execute_plugin_method("APlugin", "afterAction"), "hook test");

## This method doesn't exists.
## So, it should return undef.

is (undef,
    $sample->execute_plugin_method("APlugin", "methodWhichDoesntExists"),
	"non-exists hook");

$sample->add_hook('hook', 'sampleHook');
$sample->run_hook('hook');
$sample->run_hook('hook');

eval { ## This should die. Because of the hook doesn't exists.
	 $sample->run_hook('hoo2');
};
if ($@) {
   pass("Executing hook doesn't exists.");
}
else {
	 fail("Executing hook doesn't exists.");
}
is ($sample->getHookCounter(), 2, "Running hook method.");
