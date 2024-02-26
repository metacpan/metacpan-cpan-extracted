#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure qw(concat_position);
use Data::Transfigure::Position;
use Data::Transfigure::Default;
use Data::Transfigure::Constants;

use experimental qw(signatures);

my $book_1 = bless({id => 3, title => "War and Peace"},        'MyApp::Model::Result::Book');
my $book_2 = bless({id => 4, title => "A Tale of Two Cities"}, 'MyApp::Model::Result::Book');

my $d = Data::Transfigure::Position->new(
  position       => '/shelf/book',
  transfigurator => Data::Transfigure::Default->new(
    handler => sub ($entity) {
      return {title => $entity->{title}};
    }
  )
);

my $o = {
  shelf => {
    book => $book_1
  },
  current => $book_2
};

my $base = concat_position(undef, undef);

is($d->applies_to(value => undef, position => $base), $NO_MATCH, 'check position applies_to (hash-outer)');
is($d->applies_to(value => undef, position => concat_position($base, 'shelf')),
  $NO_MATCH, 'check position applies_to (hash-inner)');
is(
  $d->applies_to(value => undef, position => concat_position(concat_position($base, 'shelf'), 'book')),
  $MATCH_EXACT_POSITION | $MATCH_DEFAULT,
  'check position applies_to (object)'
);
is($d->applies_to(value => undef, position => concat_position($base, 'current')),
  $NO_MATCH, 'check position applies-to (wrong object)');

is($d->transfigure($o->{shelf}->{book}), {title => 'War and Peace'}, 'check transfigure at position');

$d = Data::Transfigure::Position->new(
  position       => ['/attachment', '/elements/*/attachment', '/find/**/attachment'],
  transfigurator => Data::Transfigure::Default->new(
    handler => sub ($entity) {undef}
  )
);

is($d->applies_to(value => undef, position => concat_position($base, 'current')),
  $NO_MATCH, 'check complex transfigure at position');

is($d->applies_to(value => undef, position => "/attachment"),    $MATCH_EXACT_POSITION | $MATCH_DEFAULT, "check attachment match");
is($d->applies_to(value => undef, position => "/my_attachment"), $NO_MATCH, "check attachment non-match");
is(
  $d->applies_to(value => undef, position => "/elements/4/attachment"),
  $MATCH_WILDCARD_POSITION | $MATCH_DEFAULT,
  "check inner attachment match"
);
is(
  $d->applies_to(value => undef, position => "/find/this/anywhere/attachment"),
  $MATCH_WILDCARD_POSITION | $MATCH_DEFAULT,
  "check double-wildcard attachment match"
);
is($d->applies_to(value => undef, position => "/not/this/anywhere/attachment"),
  $NO_MATCH, "check double-wildcard attachment no-match");

done_testing;
