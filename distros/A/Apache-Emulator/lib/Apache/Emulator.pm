package Apache::Emulator;
use strict;

BEGIN {
    (my $module_dir = $INC{'Apache/Emulator.pm'}) =~ s/\.pm$//;
    unshift @INC, $module_dir;
    $Apache::Emulator::VERSION = "0.06";
}
1;
