# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

#!/usr/bin/perl

use strict;
use warnings;

use CPAN::Common::Index::Mux::Ordered;
use Test::CPANfile;
use Test2::V0;

our $VERSION = 0.02;

BEGIN {
  if ($ENV{HARNESS_ACTIVE} && !$ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Run manually or set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
}

cpanfile_has_all_used_modules(
  perl_version => 5.024,
  develop => 1,
  suggests => 1,
  index => CPAN::Common::Index::Mux::Ordered->assemble(
    MetaDB => {},
    Mirror => {},
  ));

done_testing;

# End of the template. You can add custom content below this line.
