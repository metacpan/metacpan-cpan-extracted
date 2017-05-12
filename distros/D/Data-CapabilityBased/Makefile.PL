use strict;
use warnings;
use inc::Module::Install;

name('Data-CapabilityBased');

all_from('lib/Data/CapabilityBased.pm');

if ($Module::Install::AUTHOR) {
  system('pod2text lib/Data/CapabilityBased.pm > README');
}


WriteAll;
