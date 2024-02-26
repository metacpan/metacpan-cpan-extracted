#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;
use Data::Transfigure::Predicate;
use Data::Transfigure::Type;

use experimental qw(signatures);

my $predicate_toggle = 0;

my $t = Data::Transfigure->new();
$t->add_transfigurators(
  Data::Transfigure::Type->new(
    type    => 'MyApp::Book',
    handler => sub ($entity) {
      +{map {$_ => $entity->{$_}} qw(id)};
    }
  ),
  Data::Transfigure::Predicate->new(
    predicate => sub ($value, $position) {
      $predicate_toggle;
    },
    transfigurator => Data::Transfigure::Type->new(
      type    => 'MyApp::Book',
      handler => sub ($entity) {
        +{map {$_ => $entity->{$_}} qw(id title)};
      }
    )
  )
);

my $book = bless({id => 2, title => 'War and Peace'}, 'MyApp::Book');
is($t->transfigure({book => $book}), {book => {id => 2}}, 'Predicate non-match test');
$predicate_toggle = 1;
is($t->transfigure({book => $book}), {book => {id => 2, title => 'War and Peace'}}, 'Predicate match test');

done_testing;
