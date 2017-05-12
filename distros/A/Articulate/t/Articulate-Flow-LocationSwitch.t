use Test::More;
use Test::Exception;
use strict;
use warnings;

use Articulate::Item ();

use Articulate::Flow::LocationSwitch;
my $class = 'Articulate::Flow::LocationSwitch';

sub item {
  Articulate::Item->new( { location => shift } );
}
{

  package Dummy::Provider;
  use Moo;
  with 'Articulate::Role::Flow';
  has good   => is => 'rw';
  has reason => is => 'rw';

  sub process_method {
    my $self = shift;
    Test::More::ok( $self->good, $self->reason );
  }
}

sub then_pass {
  Dummy::Provider->new( { good => 1, reason => $_[0] } );
}

sub then_fail {
  Dummy::Provider->new( { good => 0, reason => $_[0] } );
}

my $test_suite = [
  {
    item => '/zone/public/article/hello-world',
    args => {
      where => {
        'zone/public/article/hello-world' => then_pass('simple match'),
      },
      otherwise => then_fail,
    },
  },
  {
    item => '/zone/public/article/hello-world',
    args => {
      where => {
        'zone/public/article/*' =>
          then_pass('asterisk in new_location_specification'),
      },
      otherwise => then_fail,
    },
  },
];

sub verify {
  my $got    = join( ',', @{ $_[0] } );
  my $expect = join( ',', @{ $_[1] } );
  my $reason = $_[2];
  is( $got, $expect, $reason );
}

foreach my $case (@$test_suite) {
  my $why = $case->{why} // '';
  subtest $why => sub {
    my $switcher = $class->new( $case->{args} );
    $switcher->augment( item $case->{item} );
    }
}

done_testing();
