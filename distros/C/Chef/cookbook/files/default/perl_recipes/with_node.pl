#!/usr/bin/perl

use Chef;

resource file => '/tmp/' . node->{attributes}->{hostname} . "_created_with_perl", sub {
  my $r = shift;
  $r->action('create');
};

1;
