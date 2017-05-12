#!/usr/bin/perl
use Test::More 'no_plan';
use lib qw (../lib lib);
use warnings;
use strict;
use Asterisk::LCR::Locale;

my $locale = Asterisk::LCR::Locale->new ('fr');
is ($locale->global_to_local ("33262"), "0262");
is ($locale->local_to_global ("0262"), "262262");

# 262,Reunion,phonext,EUR,0.099,0,30,1
# 33262,Reunion,phonext,EUR,0.349,0,30,1
# 33262692,Reunion - Mobile,phonext,EUR,0.349,0,30,1
# 33692,Reunion - Mobile,phonext,EUR,0.349,0,30,1
# 262692,Reunion - Mobile,phonext,EUR,0.199,0,30,1
# 262,reunion island proper,voipjet,USD,0.0620,0,30,6
# 262692,reunion island cellular,voipjet,USD,0.2682,0,30,6
# 262,Reunion,ykoz,EUR,0.05,0,1,1
# 262692,Reunion Mobile,ykoz,EUR,0.20,0,1,1

is ($locale->local_to_global ($locale->global_to_local ("262")) => "262262");
is ($locale->local_to_global ($locale->global_to_local ("33262")) => "262262");
is ($locale->local_to_global ($locale->global_to_local ("33692")) => "262692");
is ($locale->local_to_global ($locale->global_to_local ("262692")) => "262692");
is ($locale->global_to_local ("33262692") => "0692");
is ($locale->local_to_global ($locale->global_to_local ("33262692")) => "262692");
