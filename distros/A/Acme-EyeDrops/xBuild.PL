# The .eye files under lib/Acme are treated essentially the same
# as .pm files.

use strict;
use Module::Build;

print <<'CAMEL_GREETING';
                   ######
    #####        #########
##########      ###########
 ##########    #############
   #######   ################
  ######## ###################
  ####### #####################
  #############################
   #############################
   ##############################
    #############################
     ######################### ##
       ## ############### #### ##
          ####  ########   ### #
          ###   #### ###   ###
          ###  ##### ##     ##
          ###  ####  ##     ##
          ##   #     ##     ##
          ##    #    #      #
          ##     #  #       #
          #       ###       #
          #      ## ##      #
         ##    ####  #     ##
       ####               ####
CAMEL_GREETING

my $m = Module::Build->new(
   module_name =>     'Acme::EyeDrops',
   license =>         'perl',
   requires =>        { 'perl' => '5.006' },
   build_requires =>  { 'Module::Build' => 0.26 }
);
$m->add_build_element('eye');
$m->add_build_element('eyp');
$m->create_build_script;
