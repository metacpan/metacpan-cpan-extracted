#!/usr/bin/perl -w
use strict;
use 5.006_001;
use App::Modular;

print "1..4\n";

# paths are relative to . -> insert that in @INC
push @INC, qw (.);

# test 1 initialize modularizer
my $mod = App::Modular->instance();
if (ref($mod) ne "App::Modular") {
   print "not ok 1 initialize modularizer\n";
   print "Bail out!\n";
   print "Could not initialize modularizer -> tests are useless!\n";
   exit;
}
print "ok 1\n";

# test 2 configure modularizer
$mod->module_directory('t/events/');
$mod->module_extension('.mom');
$mod->module_autoload(1);
unless (  ($mod->module_directory eq 't/events/') 
       && ($mod->module_extension eq '.mom')
       && ($mod->module_autoload) ) {
   print "not ok 2 configure modularizer\n";
} else {
   print "ok 2 configure modularizer\n";
}

# test 3 register an event handler
$mod->module('Listener')->start_listen();
my $foundlistener=0;
foreach my $listener ($mod->module('Events')->listeners('newinput')) {
   if ($listener eq 'Listener') {
      $foundlistener++;
   }
}
unless ($foundlistener) {
   print "not ok 3 register event listener\n";
} else {
   print "ok 3 register event listener\n";
}

# test 4 trigger event/listener check
$mod->module('Input')->triggerevent();
unless ($mod->module('Listener')->gotinput()) {
   print "not ok 4 trigger event/listener check\n";
} else {
   print "ok 4 trigger event/listener check\n";
}

1;
