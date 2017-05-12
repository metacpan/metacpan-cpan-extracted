package Data::Checker::Ping;
# Copyright (c) 2013-2016 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.008;
use warnings 'all';
use strict;
use Net::Ping;
use Net::Ping::External;

our($VERSION);
$VERSION='1.08';

###############################################################################
###############################################################################

sub check {
   my($obj,$element,$desc,$check_opts) = @_;
   my $err  = [];
   my $warn = [];
   my $info = [];

   if (! defined $check_opts) {
      $check_opts = { 'tcp' => undef };
   }

   # Do the pings

   foreach my $proto (qw(tcp udp icmp stream syn external)) {
      next  if (! $obj->check_performed($check_opts,$proto));

      my $ping     = Net::Ping->new($proto);
      my $timeout  = $obj->check_option($check_opts,'timeout',5,$proto);
      my $up       = ($ping->ping($element,$timeout) ? 1 : 0);

      $obj->check_value($check_opts,$proto,$element,$up,
                        "Host does not respond to $proto pings",
                        "Host does respond to $proto pings",
                        $err,$warn,$info);
      return ($element,$err,$warn,$info)  if (@$err);
   }

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
