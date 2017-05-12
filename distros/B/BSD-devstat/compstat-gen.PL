#!/usr/bin/perl
#
# Copyright (c) 2010  S2 Factory, Inc.  All rights reserved.
#
# $Id$

use strict;
use warnings;

open(my $fh, "<", "compstat.txt") or die;

print <<END;
int
compstat(struct devstat *current, struct devstat *previous, long double etime, HV* rh)
{
    u_int64_t u[14];
    long double d[23];
    devstat_compute_statistics(current, previous, etime,
END

my ($u, $d, @u, @d) = (0, 0);
while (<$fh>) {
  chomp;
  my ($key, $type) = split(/\t+/, $_, 2);
  if ($type eq 'u') {
    push @u, [ $key, $u ];
    printf "    DSM_%s, &u[%d],\n", $key, $u++;
  } elsif ($type eq 'd') {
    push @d, [ $key, $d ];
    printf "    DSM_%s, &d[%d],\n", $key, $d++;
  } else {
    die;
  }
}

print <<END;
    DSM_NONE);
END

foreach (@u) {
  printf("    hv_store(rh, \"%s\", %d, newSViv(u[%d]), 0);\n",
	 $_->[0], length($_->[0]), $_->[1]);
}
foreach (@d) {
  printf("    hv_store(rh, \"%s\", %d, newSVnv(d[%d]), 0);\n",
	 $_->[0], length($_->[0]), $_->[1]);
}

print <<END;
}
END
