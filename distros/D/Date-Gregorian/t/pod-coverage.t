# Copyright (c) 2006-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# check for POD coverage

eval "use Test::Pod::Coverage 0.08";
if ($@) {
   print
       "1..0 # Skip ",
       "Test::Pod::Coverage 0.08 required for testing POD coverage\n";
   exit 0;
}

all_pod_coverage_ok();

__END__
