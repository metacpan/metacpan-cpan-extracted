use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;

requires undef, 23;
extract_data;

run_ok('foo', 'which', 'bar')
  ->exit_is(0)
  ->out_like(qr{type:\s*helper})
  ->out_like(qr{class:\s*Foo})
  ->out_like(qr{location:.*Foo.pm:[0-9]+})
  ->out_unlike(qr{name:})
  ->note;

run_ok('foo', 'which', 'baz')
  ->exit_is(0)
  ->out_like(qr{name:\s*_baz})
  ->note;

run_ok('foo', 'which', 'autobot')
  ->exit_is(0)
  ->out_like(qr{name:\s*autobot})
  ->out_like(qr{type:\s*controller method})
  ->note;

run_ok('foo', 'which', '_baz')
  ->exit_is(0)
  ->out_like(qr{name:\s*_baz})
  ->out_like(qr{type:\s*app method})
  ->note;

run_ok('foo', 'which')
  ->exit_is(1)
  ->err_like(qr{no method specified})
  ->note;

run_ok('foo', 'which', 'bogus')
  ->exit_is(2)
  ->err_like(qr{No such method or helper: bogus})
  ->note;

__DATA__

@@ bin/foo
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Foo';
Clustericious::Commands->start;


@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );

sub startup
{
  my($self, @args) = @_;
  $self->SUPER::startup(@args);
  $self->helper( bar => sub { } );
  $self->helper( baz => \&_baz );
}

sub _baz {};

sub Clustericious::Controller::autobot {}

1;
