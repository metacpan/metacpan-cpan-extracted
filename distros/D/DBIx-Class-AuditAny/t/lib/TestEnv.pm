package # hide from PAUSE
     TestEnv;

use strict;
use warnings;

use Path::Class qw(dir file);
use FindBin '$Bin';

our $CLEANUP_SAFE = 0;

sub vardir {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  dir("$Bin/var");
}


sub import {
  my $var = &vardir;
  
  die "tmp/var dir '$var' already exists, please remove and try again"
    if (-e $var);
  
  $CLEANUP_SAFE = 1 if $var->mkpath;
}

END {
  my $var = &vardir;
  $var->rmtree if $CLEANUP_SAFE;
}

1;