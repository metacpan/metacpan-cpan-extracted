#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::RefVars;

ok(defined($Config::INI::RefVars::VERSION), '$VERSION is defined');

foreach my $meth (qw(new
                     global_mode
                     parse_ini
                     sections
                     sections_h
                     variables
                     src_name
                     tocopy_section
                     current_tocopy_section
                     separator
                   )) {
  ok(Config::INI::RefVars->can($meth), "$meth() exists");
}

#==================================================================================================
done_testing();
