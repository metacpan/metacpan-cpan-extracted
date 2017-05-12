#!/usr/bin/env perl
use strict;
use warnings;
use lib ( '.', '../t' );
use Test::More tests => 4;
use Data::FormValidator;

# This test is a for a bug where a value doesn't get filtered when it should
# The bug was discovered by Jeff Till, and he contributed this test, too.
# Verify that multiple params passed to a constraint are being filtered
my $validator = new Data::FormValidator( {
    default => {
      filters     => ['trim'],
      required    => [qw/my_junk_field my_other_field/],
      constraints => {
        my_junk_field => {
          constraint => \&letters_2_var,
          name       => 'zipcode',

        },
        my_other_field => \&letters,
      },
    },
  } );

sub letters_2_var
{
  if ( $_[0] =~ /^[a-z]+$/i )
  {
    return 1;
  }
  return 0;
}

sub letters
{
  if ( $_[0] =~ /^[a-z]+$/i )
  {
    return 1;
  }
  return 0;
}

my $input_hashref = {
  my_junk_field  => 'foo ',
  my_other_field => ' bar',
};

my ( $valids, $missings, $invalids, $unknowns ) =
  $validator->validate( $input_hashref, 'default' );

is_deeply( $invalids, [], "all fields are valid" );

{    # RT#13078
  my $res;
  eval {
    $res = Data::FormValidator->check( {
        local_filter        => ' needs@trimmed.com ',
        global_filter_field => ' needs@trimmed.com ',
      },
      {
        required => [ 'local_filter', 'global_filter_field' ],
        filters => [ sub { my $v = shift; $v =~ s/needs/global/g; $v }, ],
        field_filters => {
          local_filter => 'trim',
        },
        constraints => {
          local_filter => [
            'email',
            {
              constraint => sub {
                my $val = shift;
                return ( $val eq 'global@trimmed.com' );
              },
              params => ['local_filter'],
            }
          ],
          global_filter_field => [
            sub {
              my $val = shift;
              if ( $val eq ' global@trimmed.com ' )
              {
                return 1;
              }
              else
              {
                warn
                  "without param got: '$val', expected 'global\@trimmed.com'";
                return undef;
              }
            },
            {
              constraint => sub {
                my $val = shift;
                if ( $val eq ' global@trimmed.com ' )
                {
                  return 1;
                }
                else
                {
                  warn
                    " using param got: '$val', expected 'global\@trimmed.com'";
                  return undef;
                }
              },
              params => ['global_filter_field'],
            },
          ]
        },
      } );
  };
  is( $@, '', 'survived eval' );

  eval
  {
    ok( $res->valid('local_filter'),
      " when passed through param, local filters are applied." );
  };
  eval
  {
    ok( $res->valid('global_filter_field'),
      " when passed through param, global filters are applied." );
  };
}
