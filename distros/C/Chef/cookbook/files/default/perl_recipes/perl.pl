#!/usr/bin/perl

use Chef;

resource file => '/tmp/foo', sub {
  my $r = shift;
  $r->owner('adam');
  $r->action('create');
};

1;
