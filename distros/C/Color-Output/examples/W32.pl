#!/usr/bin/perl
################################################################################
# This example will always use Win32::Console even on the system that does     #
# NOT have this module/package                                                 #
#                                                                              #
################################################################################
use Color::Output;
$Color::Output::Mode = 2;
Color::Output::Init;

cprint "\x035This text will be colored red on systems that do have the Win32::Console-module/package installed.\x030\n";
