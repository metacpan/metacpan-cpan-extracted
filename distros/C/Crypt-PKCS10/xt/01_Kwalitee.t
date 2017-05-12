# -*- mode: cperl; -*-

# Release tests for Crypt::PKCS10

# Copyright (c) 2016 Timothe Litt
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# Terms of the Perl programming language system itself
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 1, or (at your option) any
#   later version, or
# b) the "Artistic License"
#
# See LICENSE for details.
#

use warnings;
use strict;

use Test::More 0.94;

use File::Spec;

BEGIN {
        my $distdir = File::Spec->catdir( (File::Spec->splitpath($0))[0,1], File::Spec->updir );
        chdir $distdir or die "$distdir: $!\n";
}

 use Test::More;
  BEGIN {
      plan skip_all => 'these tests are for release candidate testing'
          unless $ENV{RELEASE_TESTING};
  }

  use Test::Kwalitee 'kwalitee_ok';
  kwalitee_ok();
  done_testing;
