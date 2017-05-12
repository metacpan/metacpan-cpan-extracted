#!/usr/bin/perl

package Y;
sub new { bless { foo => 'foo', bar => 'bar' }, shift; }
sub foo { shift->{'foo'}; }
sub bar {
  my ($self, $new) = @_;
  defined $new and $self->{'bar'} = $new;
  $self->{'bar'};
}

package X;

use Test;
BEGIN { plan tests => 11 }

use Class::MakeMethods::Template::Array
  new => 'new',
  object  => [ 
    '--get_set_init',
    '-class' => 'Y',
    'a',
    [ qw / b c d / ],
    {
      name => 'e',
      delegate => [ qw / foo / ],
    },
    {
      name => 'f',
      delegate => [ qw / bar / ],
    }
  ];

my $o = new X;

ok( 1 ); #1

ok( ref $o->a eq 'Y' ); #2
ok( ref $o->b eq 'Y' ); #3

my $y = new Y;
ok( $o->c($y) ); #4
ok( $o->c eq $y ); #5
ok( ref $o->c eq 'Y' ); #6

ok( ref $o->e eq 'Y' ); #7

ok( $o->foo eq 'foo' ); #8
ok( $o->bar('bar') ); #9
ok( $o->bar eq 'bar' ); #10

ok( $o->e->foo eq $o->foo ); #11

exit 0;

