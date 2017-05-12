package Data::Checker::Date;
# Copyright (c) 2014-2016 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.008;
use warnings 'all';
use strict;
use Date::Manip;

our($VERSION);
$VERSION='1.08';

###############################################################################
###############################################################################

sub check {
   my($obj,$element,$desc,$check_opts) = @_;
   my $err    = [];
   my $warn   = [];
   my $info   = [];

   #
   # Must be a valid date.
   #
   # Must be any of the forms supported by Date::Manip.
   #

   my $date   = ParseDate($element);
   my $valid  = ($date ? 1 : 0);
   $obj->check_value($check_opts,undef,$element,$valid,
                     "Not a valid date",undef,
                     $err,$warn,$info);
   return ($element,$err,$warn,$info);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
