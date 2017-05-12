#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Clutter;

Clutter->init(undef);

{
  my $stage = Clutter::Stage->new();
  ok( defined $stage, 'stage is defined' );
  isa_ok( $stage, 'Clutter::Stage', 'stage is a Clutter::Stage' );
  isa_ok( $stage, 'Clutter::Actor', 'stage is a Clutter::Actor' );
  isa_ok( $stage, 'Clutter::Container', 'stage is a Clutter::Container' );

  $stage->set_title('foo');
  ok( $stage->get_title() eq 'foo', 'stage:title' );

  $stage->signal_connect(destroy => sub { ok(1) });
  $stage->destroy();
}

{
  my $stage = Clutter::Stage->new();
  $stage->set_title('test');
  $stage->set_size(200, 200);
  $stage->show();
  $stage->signal_connect(destroy => sub { Clutter->main_quit(); });

  Glib::Timeout->add(1000, sub { $stage->destroy(); });

  Clutter->main();
}

{
  my $stage = Clutter::Stage->get_default();
  ok( defined $stage );
  isa_ok( $stage, 'Clutter::Stage' );
}

done_testing();
