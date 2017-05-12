#############################################################################
# test-script.pl -- simple testing script for AtExit.pm
#
# Copyright (c) 1996 Andrew Langmead. All rights reserved.
# This file is part of "AtExit". AtExit is free software;
# you can redistribute it and/or modify it under the same
# terms as Perl itself.
#############################################################################

use strict;
use warnings;

use AtExit;

sub cleanup {
    my @args = @_;
    print "cleanup() executing: args = @args\n";
}

## Register subroutines to be called when this program exits

$_ = atexit(\&cleanup, "This call was registered first");
print "first call to atexit() returned value of type ", ref($_), "\n";

$_ = atexit("cleanup", "This call was registered second");
print "second call to atexit() returned value of type ", ref($_), "\n";

$_ = atexit("cleanup", "This call should've been unregistered by rmexit");
rmexit($_)  or  warn "couldnt' unregister exit-sub $_!";

if (@ARGV == 0) {
   ## Register subroutines to be called when this lexical scope is exited
   my $scope1 = AtExit->new( \&cleanup, "Scope 1, Callback 1" );
   {
      ## Do the same for this nested scope
      my $scope2 = AtExit->new;
      $_ = $scope2->atexit( \&cleanup, "Scope 2, Callback 1" );
      $scope1->atexit( \&cleanup, "Scope 1, Callback 2");
      $scope2->atexit( \&cleanup, "Scope 2, Callback 2" );
      $scope2->rmexit($_) or warn "couldn't unregister exit-sub $_!";

      print "*** Leaving Scope 2 ***\n";
      #$scope2->rmexit();
    }
    print "*** Finished Scope 2 ***\n";
    print "*** Leaving Scope 1 ***\n";
}
print "*** Finished Scope 1 ***\n"  if (@ARGV == 0);
##rmexit();
END {
    print "*** Now performing program-exit processing ***\n";
}

exit 0;
