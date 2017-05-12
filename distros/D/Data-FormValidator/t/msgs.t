#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator;

my $simple_profile = {
  required    => [qw/req_1 req_2/],
  optional    => [qw/opt_1/],
  constraints => {
    req_1 => 'email'
  },
  msgs => {},
};

my $simple_data = { req_1 => 'not_an_email', };

my $prefix_profile = {
  required    => [qw/req_1 req_2/],
  optional    => [qw/opt_1/],
  constraints => {
    req_1 => 'email'
  },
  msgs => {
    prefix     => '',
    any_errors => 'err__',
  },
};

my $input_profile = {
  required    => [qw(admin prefork sleep rounds)],
  constraints => {
    admin   => "email",
    prefork => sub {
      my $val = shift;
      if ( $val =~ /^\d$/ )
      {
        if ( $val > 1 and $val < 9 )
        {
          return $val;
        }
      }
      return 0;
    },
    sleep => [
      'email',
      {
        name       => 'min',
        constraint => sub {
          my $val = shift;
          if ( $val > 0 )
          {
            return $val;
          }
          else
          {
            return 0;
          }
        }
      },
      {
        name       => 'max',
        constraint => sub {
          my $val = shift;
          if ( $val < 11 )
          {
            return $val;
          }
          else
          {
            return 0;
          }
        }
      }
    ],
    rounds => [ {
        name       => 'min',
        constraint => sub {
          my $val = shift;
          if ( $val > 19 )
          {
            return $val;
          }
          else
          {
            return 0;
          }
        }
      },
      {
        name       => 'max',
        constraint => sub {
          my $val = shift;
          if ( $val < 101 )
          {
            return $val;
          }
          else
          {
            return 0;
          }
        }
      } ]
  },
  msgs => {
    missing           => 'Test-Missing',
    invalid           => 'Test-Invalid',
    invalid_seperator => ' ## ',

    constraints => {
      max => 'needs to be lesser than 11',
      min => 'needs to be greater than 0'
    },
    format => 'ERROR: %s',
    prefix => 'error_',
  } };

my $validator = new Data::FormValidator( {
  simple  => $simple_profile,
  default => $input_profile,
  prefix  => $prefix_profile,
} );

my $input_hashref =
  { admin => 'invalidemail', prefork => 9, sleep => 11, rounds => 8 };

my $results;
eval { $results = $validator->check( $simple_data, 'simple' ); };
ok( not $@ );

TODO:
{
  local $TODO = 'need to test for msgs() called before validate';

  # msgs() should return emit a warning and return undef if the hash
  # structure it points to is undefined. However, if it points to an
  # empty hash, then maybe there are just no messages.
}

# testing simple msg definition, $self->msgs should be returned as a hash ref
my $msgs;
eval { $msgs = $results->msgs; };
ok( ( not $@ ), 'existence of msgs method' )
  or diag $@;

ok( ref $msgs eq 'HASH', 'invalid fields returned as hash in simple case' );

like( $msgs->{req_1}, qr/Invalid/, 'default invalid message' );
like( $msgs->{req_2}, qr/Missing/, 'default missing message' );
like( $msgs->{req_1}, qr/span/,    'default formatting' );

# testing single constraints and single error case
eval { $results = $validator->check( $input_hashref, 'default' ); };
is( $@, '', 'survived eval' );
$msgs = $results->msgs;

like( $msgs->{error_sleep}, qr/lesser.*Test|Test.*lesser/,
  'multiple constraints constraint definition' );

eval { $results = $validator->check( $simple_data, 'prefix' ); };
is( $@, '', 'survived eval' );

$msgs = $results->msgs( { format => 'Control-Test: %s' } );

ok( defined $msgs->{req_1}, 'using default prefix' );
is( keys %$msgs, 3, 'size of msgs hash' );    # 2 errors plus 1 prefix
ok( defined $msgs->{err__}, 'any_errors' );
like( $msgs->{req_1}, qr/Control/, 'passing controls to method' );

# See what happens when msgs is called with it does not appeare in the profile
my @basic_input = ( {
    field_1 => 'email',
  },
  {
    required => 'field_1',

  } );
$results = Data::FormValidator->check(@basic_input);
eval { $results->msgs };
ok( ( not $@ ), 'calling msgs method without hash definition' );

###
{
  my $test_name = 'Spelling "separator" correctly should work OK.';
  my $results   = Data::FormValidator->check( {
      field => 'value',
    },
    {
      required    => [qw/field/],
      constraints => {
        field => [ 'email', 'province' ],
      },
      msgs => {
        invalid_separator => ' ## ',
      },
    } );

  my $msgs = $results->msgs;
  like( $msgs->{field}, qr/##/, $test_name );
}

###
{
  my $test_name = 'A callback can be used for msgs';
  my $results   = Data::FormValidator->check( {
      field => 'value',
    },
    {
      required    => [qw/field/],
      constraints => {
        field => [ 'email', 'province' ],
      },
      msgs => sub { { field => 'callback!' } },
    } );

  my $msgs = $results->msgs;
  like( $msgs->{field}, qr/callback/, $test_name );

}
