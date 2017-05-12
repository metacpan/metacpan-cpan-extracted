#!/usr/bin/perl
################################################################################
# This example will use an other Color-symbol then the default one             #
#                                                                              #
################################################################################
use Color::Output;
$Color::Output::Symbol = chr(4);
Color::Output::Init;

cprint "\x035This text is not red.\x04\n";
cprint "\x043This text is blue.\n";
cprint chr(4) . "13And this line is colored yellow.\n";
