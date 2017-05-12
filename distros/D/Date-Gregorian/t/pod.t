# Copyright (c) 2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# check whether POD parses without errors or warnings

eval "use Test::Pod 1.00";
if ($@) {
   print "1..0 # Skip Test::Pod 1.00 required for testing POD\n";
   exit 0;
}

all_pod_files_ok();

__END__
