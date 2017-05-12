use Test::More;
use Test::Exception;
use strict;
use warnings;

use Articulate::Item ();

use Articulate::Flow::MetaSwitch;
my $class = 'Articulate::Flow::MetaSwitch';

sub item {
  Articulate::Item->new( { meta => shift } );
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
    item => { schema => { core => { file => 1 } } },
    args => {
      where => [
        {
          field => '/schema/core/file',
          then  => then_pass('undefined value implies truth check'),
        },
      ],
      otherwise => then_fail,
    },
  },
  {
    item => { schema => { core => { file => 1 } } },
    args => {
      where => [
        {
          field => '/schema/core/foo',
          then  => then_fail,
        },
      ],
      otherwise => then_pass(
        'undefined value implies truth check (otherwise case triggered)'),
    },
  },
  {
    item => { schema => { core => { dateUpdated => '2014-01-01' } } },
    args => {
      where => [
        {
          field => '/schema/core/dateUpdated',
          value => '2014-01-02',
          then  => then_fail('does not match'),
        },
        {
          field => '/schema/core/dateUpdated',
          value => '2014-01-01',
          then  => then_pass('simple comparison succeeds'),
        },
      ],
      otherwise => then_fail,
    },
  },
  {
    item => { schema => { core => { dateUpdated => '2014-01-01' } } },
    args => {
      field => '/schema/core/dateUpdated',
      where => {
        '2014-01-02' => then_fail('does not match'),
        '2014-01-01' => then_pass('simple comparison succeeds'),
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
