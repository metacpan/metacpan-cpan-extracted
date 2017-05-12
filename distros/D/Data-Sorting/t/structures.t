#!perl
use strict;
use Test::More tests => 17;
BEGIN { use_ok('Data::Sorting'); }
require 't/sort_tests.pl';

test_sort_cases (
  {
    values => [ 
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
    ],
    sorted => [ 'foo' ],
  },
  {
    values => [ 
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
    ],
    sorted => [ 'bar' ],
  },
  {
    values => [ 
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
    ],
    sorted => [ sub { (shift)->{bar} } ],
  },
  {
    values => [ 
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
    ],
    sorted => [ 'baz' ],
    okidxs => [ [ 1, 2, 3, 4 ], [ 2, 1, 3, 4 ], [ 1, 2, 4, 3 ], [ 2, 1, 4, 3 ] ]
  },
  {
    values => [ 
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
    ],
    sorted => [ 'baz', 'foo' ],
  },
  {
    values => [ 
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
    ],
    sorted => [ 'baz', 'bar' ],
  },
  {
    values => [ 
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
    ],
    sorted => [ 'baz', -order => 'reverse', 'bar' ],
  },
  {
    values => [ 
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
    ],
    sorted => [ -order => 'reverse', 'baz', 'bar' ],
  },
  {
    values => [ 
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
    ],
    sorted => [ -order => 'reverse', 'baz', -order => 'forward', 'bar' ],
  },
  {
    values => [ 
      { foo => 'Gamma', bar => 'Chi', baz => 'On' },
      { foo => 'Alpha', bar => 'Sigma', baz => 'On' },
      { foo => 'Beta', bar => 'Delta', baz => 'Off' },
      { foo => 'Omega', bar => 'Epsilon', baz => 'Off' },
    ],
    sorted => [ { order => 'reverse', sortkey => 'baz' }, 'bar' ],
  },
  {
    values => [ 
      [ 'art', { foo => 'Omega', bar => 'Epsilon', baz => 'Off' } ],
      [ 'cat', { foo => 'Beta', bar => 'Delta', baz => 'Off' } ],
      [ 'dog', { foo => 'Gamma', bar => 'Chi', baz => 'On' } ],
      [ 'set', { foo => 'Alpha', bar => 'Sigma', baz => 'On' } ],
    ],
    sorted => [ 0 ],
  },
  {
    values => [ 
      [ 'set', { foo => 'Alpha', bar => 'Sigma', baz => 'On' } ],
      [ 'cat', { foo => 'Beta', bar => 'Delta', baz => 'Off' } ],
      [ 'dog', { foo => 'Gamma', bar => 'Chi', baz => 'On' } ],
      [ 'art', { foo => 'Omega', bar => 'Epsilon', baz => 'Off' } ],
    ],
    sorted => [ [ 1, 'foo' ] ],
  },
  {
    values => [ 
      [ 'dog', { foo => 'Gamma', bar => 'Chi', baz => 'On' } ],
      [ 'cat', { foo => 'Beta', bar => 'Delta', baz => 'Off' } ],
      [ 'art', { foo => 'Omega', bar => 'Epsilon', baz => 'Off' } ],
      [ 'set', { foo => 'Alpha', bar => 'Sigma', baz => 'On' } ],
    ],
    sorted => [ [ 1, 'bar' ] ],
  },
  {
    values => [ 
      { foo => 'Gamma', bar => [ 'Chi', 'dog' ], baz => 'On' },
      { foo => 'Beta', bar => [ 'Delta', 'cat' ], baz => 'Off' },
      { foo => 'Omega', bar => [ 'Epsilon', 'art' ], baz => 'Off' },
      { foo => 'Alpha', bar => [ 'Sigma', 'set' ], baz => 'On' },
    ],
    sorted => [ [ 'bar', 0 ] ],
  },
  {
    values => [ 
      { foo => 'Omega', bar => [ 'Epsilon', 'art' ], baz => 'Off' },
      { foo => 'Beta', bar => [ 'Delta', 'cat' ], baz => 'Off' },
      { foo => 'Gamma', bar => [ 'Chi', 'dog' ], baz => 'On' },
      { foo => 'Alpha', bar => [ 'Sigma', 'set' ], baz => 'On' },
    ],
    sorted => [ [ 'bar', 1 ] ],
  },
  {
    values => [ 
      { foo => 'Beta', bar => [ 'Delta', 'cat' ], baz => 'Off' },
      { foo => 'Omega', bar => [ 'Epsilon', 'art' ], baz => 'Off' },
      { foo => 'Gamma', bar => [ 'Chi', 'dog' ], baz => 'On' },
      { foo => 'Alpha', bar => [ 'Sigma', 'set' ], baz => 'On' },
    ],
    sorted => [ 'baz', [ 'bar', 0 ] ],
  },
);
