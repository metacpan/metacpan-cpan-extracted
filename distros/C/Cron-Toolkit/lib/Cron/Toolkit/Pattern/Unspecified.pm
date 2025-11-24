package Cron::Toolkit::Pattern::Unspecified;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'unspecified';
}

sub match {
   return 1;
}

1;
