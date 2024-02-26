#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure::Default;
use Data::Transfigure::Constants;

use experimental qw(signatures);

my $d = Data::Transfigure::Default->new(
  handler => sub ($entity) {
    return 'SCALAR';
  }
);

my $o = {
  a => 1,
  b => 2,
  c => bless({id => 3, title => 'War and Peace'}, 'MyApp::Model::Result::Book'),
};

is($d->applies_to(value => $o),      $NO_MATCH,      'hashes excluded from default matching');
is($d->applies_to(value => []),      $NO_MATCH,      'arrays excluded from default matching');
is($d->applies_to(value => $o->{a}), $MATCH_DEFAULT, 'default match of scalar (a => 1)');
is($d->applies_to(value => $o->{b}), $MATCH_DEFAULT, 'default match of scalar (b => 2)');
is($d->applies_to(value => $o->{c}), $MATCH_DEFAULT, 'default match of scalar (c => custom class instance)');

is($d->transfigure($o),      'SCALAR', 'basic default transfigure (hash)');
is($d->transfigure($o->{a}), 'SCALAR', 'basic default transfigure (a)');
is($d->transfigure($o->{b}), 'SCALAR', 'basic default transfigure (b)');
is($d->transfigure($o->{c}), 'SCALAR', 'basic default transfigure (c)');

$d = Data::Transfigure::Default->new(
  handler => sub ($entity) {
    return 'OBJECT' if (ref($entity));
    return "$entity";
  }
);

is($d->transfigure($o),      'OBJECT', 'deobjectifying default transfigure (hash)');
is($d->transfigure($o->{a}), "1",      'deobjectifying default transfigure (a)');
is($d->transfigure($o->{b}), "2",      'deobjectifying default transfigure (b)');
is($d->transfigure($o->{c}), 'OBJECT', 'deobjectifying default transfigure (c)');

done_testing;
