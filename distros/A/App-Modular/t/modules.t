#!/usr/bin/perl -w
use strict;
use 5.006_001;
use App::Modular;

push @INC, qw(.);

print "1..9\n";

# test 1 initialize modularizer
my $mod = App::Modular->instance();
if (ref($mod) ne "App::Modular") {
   print "not ok 1 initialize App::Modular\n";
   print "Bail out! ";
   print "Could not initialize App::Modular -> tests are useless!\n";
   exit;
}
#$mod->loglevel(101);
print "ok 1\n";

# test 2 configure modularizer
$mod->module_directory('t/modules/');
$mod->module_extension('.mom');
$mod->module_autoload(1);
unless (  ($mod->module_directory eq 't/modules/') 
       && ($mod->module_extension eq '.mom')
       && ($mod->module_autoload) ) {
   print "not ok 2 configure App::Modular\n";
} else {
   print "ok 2 configure App::Modular\n";
}

# test 3/4 (de-)register module 'Dummy'
$mod->module_register('Dummy');
unless (defined $mod->module('Dummy')) {
   print "not ok 3 register module 'Dummy'\n";
} else {
   print "ok 3 register module 'Dummy'\n";
   $mod -> module_deregister('Dummy');
   unless (! $mod->module_isloaded('Dummy')) {
      print "not ok 4 deregister module 'Dummy'\n";
   } else {
      print "ok 4 deregister module 'Dummy'\n";
   }
}

# test 5 module autoload (Noop module)
unless ($mod->module('Noop')->noop()) {
   print "not ok 5 module autoload (Noop module)\n";
} else {
   print "ok 5 module autoload (Noop module)\n";
}

# test 6 dependency autosolve
unless ($mod->module('Helloworld')->stringhello() eq 'Hello, World!') {
   print "not ok 6 dependency autosolve\n";
} else {
   print "ok 6 dependency autosolve\n";
}

# test 7 unload all modules
$mod->modules_deregister_all();
unless ((0+$mod->modules()) == 0) {
   print "not ok 7 unload all modules\n";
} else {
   print "ok 7 unload all modules\n";
}

# test 8 load categorized module (Family::Child)
$mod->module_register('Family::Child');

unless ($mod->module('Family::Child')) {
   print "not ok 8 load categorized module (Family::Child)\n";
} else {
   print "ok 8 load categorized module (Family::Child)\n";
}

# test 9 work with Family::Child
if ($mod->module('Family::Child')) {
   my @parents = $mod->module('Family::Child')->parents();
   unless (defined $parents[0] && defined $parents[1] ) {
      print "not ok 9 work with Family::Child (- no parents -)\n";
   } else {
      unless ($parents[0] =~ /\w+/
           && $parents[1] =~ /\w+/) {
         print "not ok 9 work with Family::Child (parents' names)\n";
      } else {
         print "ok 9 work with Family::Child (who are the parents?)\n";
      }
   };
};


1;
