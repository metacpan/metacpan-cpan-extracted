#!/usr/bin/perl
################################################################################
# This example will always use ANSI Colors, even on systems that does NOT      #
# support them.                                                                #
#                                                                              #
################################################################################
use Color::Output;
$Color::Output::Mode = 1;
Color::Output::Init;

cprint "\x035This text will be colored red on systems that support ANSI escape sequences.\x030\n";
