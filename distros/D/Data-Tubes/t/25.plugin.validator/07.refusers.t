use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;
use Scalar::Util qw< refaddr >;

use Data::Tubes qw< summon >;

summon('Validator::refuse_comment');
summon('Validator::refuse_comment_or_empty');
summon('Validator::refuse_empty');
ok __PACKAGE__->can('refuse_comment'), "summoned refuse_comment";
ok __PACKAGE__->can('refuse_comment_or_empty'),
  "summoned refuse_comment_or_empty";
ok __PACKAGE__->can('refuse_empty'), "summoned refuse_empty";

ok refuse_comment({input => undef})->('whatever'), 'non-comment line';
ok !refuse_comment({input => undef})->('# whatever'),   'comment line';
ok !refuse_comment({input => undef})->('  # whatever'), 'comment line, 2';
ok refuse_comment()->({raw => 'whatever'}), 'non-comment line, raw';
ok refuse_comment()->({raw => ''}),         'empty line against comment';

ok refuse_comment_or_empty({input => undef})->('whatever'),
  'non-comment line';
ok !refuse_comment_or_empty({input => undef})->('# whatever'),
  'comment line';
ok !refuse_comment_or_empty({input => undef})->('  # whatever'),
  'comment line, 2';
ok refuse_comment_or_empty()->({raw => 'whatever'}),
  'non-comment line, raw';
ok !refuse_comment_or_empty()->({raw => ''}),
  'empty line against comment_or_empty';

ok refuse_empty({input => undef})->('whatever'), 'non-empty line';
ok !refuse_empty({input => undef})->(''),   'empty line';
ok refuse_empty()->({raw => 'whatever'}), 'non-empty line, raw';
ok !refuse_empty()->({raw => ''}),         'empty line, raw';

done_testing();
