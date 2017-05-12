#!/usr/bin/env perl
use strict;
use warnings;
use inc::latest;

#               Module::Build
#               version
foreach my $module (qw(
               Locale::Maketext::Simple
               Params::Check
               Module::Load
               Module::Load::Conditional
               IPC::Cmd
               Archive::Extract
               File::Fetch))
{
  inc::latest->bundle_module($module, 'inc');
}

