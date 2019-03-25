#!/usr/bin/env perl

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::Most;
use Test::Output qw( output_is output_like );

## no critic [RegularExpressions::ProhibitFixedStringMatches]
## no critic [ValuesAndExpressions::ProhibitMagicNumbers]

local $ENV{COLUMNS} = 42;
delete local $ENV{IFS};
delete local $ENV{PS4};

require_ok 'App::ppll';

output_is {
  is App::ppll->new( argv => [qw( --version )] )->call, 0, 'Exit code 0';
}
"$App::ppll::VERSION\n", '', '--version';

output_like {
  App::ppll->new( argv => [qw( -j 1 -s 1..4 echo )] )->call;
}
qr/\b1\b.*\b2\b.*\b3\b.*\b4\b/s, qr/\b4\/4\b.*\b0\s+failed\b/s, 'Sequence';

subtest 'Single command, no parameters' => sub {
  plan skip_all => '😾'
    if $ENV{CI};

  output_like {
    App::ppll->new( argv => [qw( --summary true )] )->call;
  }
  qr/^$/, qr/\+ true\b.*━{42}.*\b1\/1\b.*\b0\s+failed\b/s, 'Good';

  output_like {
    App::ppll->new( argv => [qw( false )] )->call;
  }
  qr/^$/, qr/\+ false\b/s, 'Bad';

};

subtest _parse_sequence => sub {
  my $ppll = App::ppll->new;

  is_deeply( [ $ppll->_parse_sequence( '4' ) ], [qw( 1 2 3 4 )] );

  is_deeply( [ $ppll->_parse_sequence( '0..3' ) ],  [qw( 0 1 2 3 )] );
  is_deeply( [ $ppll->_parse_sequence( '1..4' ) ],  [qw( 1 2 3 4 )] );
  is_deeply( [ $ppll->_parse_sequence( '2..10' ) ], [ 2 .. 10 ] );
  is_deeply( [ $ppll->_parse_sequence( '10..2' ) ], [ reverse( 2 .. 10 ) ] );

  is_deeply( [ $ppll->_parse_sequence( '4..1' ) ], [qw( 4 3 2 1 )] );
  is_deeply(
    [ $ppll->_parse_sequence( '01..10' ) ],
    [ map { sprintf '%02d', $_ } 1 .. 10 ] );

  is_deeply( [ $ppll->_parse_sequence( 'a..d' ) ], [qw( a b c d )] );

  is_deeply( [ $ppll->_parse_sequence( '1..4,a..d' ) ],
    [qw( 1 2 3 4 a b c d )] );
};

subtest _split_fields => sub {
  my $ppll = App::ppll->new;

  is_deeply( [ $ppll->_split_fields( 'foo bar' ) ],
    [qw( foo bar )], 'Two words' );
};

done_testing;
