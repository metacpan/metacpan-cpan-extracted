# Copyright (c) 2007-2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 90_pod.t'

# check whether POD parses without errors or warnings

my $env_maint = 'MAINTAINER_OF_DATE_GREGORIAN';
if (!$ENV{$env_maint}) {
    print "1..0 # SKIP setenv $env_maint=1 to run these tests\n";
    exit 0;
}

eval "use Test::Pod 1.00";
if ($@) {
   print "1..0 # SKIP Test::Pod 1.00 required for testing POD\n";
   exit 0;
}

all_pod_files_ok();

__END__
