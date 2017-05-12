use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon([qw< Plumbing alternatives fallback >]);
ok __PACKAGE__->can('alternatives'), "summoned alternatives";
ok __PACKAGE__->can('fallback'),     "summoned fallback";

{
   my @outcome;
   my @exceptions;
   lives_ok {
      @outcome = alternatives(
         sub { return },    # ignored, returns nothing
         fallback(
            sub { die ['bar'] },
            sub { die {baz => 1} },
            { catch => sub { push @exceptions, shift } },
         ),              # ignored
         ['Parser::by_format', format => 'foo,bar'],    # this goes
      )->({raw => 'FOO,BAR'});
   } ## end lives_ok
   'alternatives lives';

   is_deeply \@outcome,
     [{raw => 'FOO,BAR', structured => {foo => 'FOO', bar => 'BAR'}}],
     'outcome of alternatives'
     or diag Dumper \@outcome;

   is_deeply \@exceptions, [['bar'],{baz => 1}], 'exceptions were trapped';
}

done_testing();
