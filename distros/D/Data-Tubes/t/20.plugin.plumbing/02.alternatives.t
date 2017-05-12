use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Plumbing::alternatives');
ok __PACKAGE__->can('alternatives'), "summoned alternatives";

{
   my @outcome;
   lives_ok {
      @outcome = alternatives(
         sub { return },    # ignored, returns nothing
         ['Parser::by_format', format => 'foo,bar'],    # this goes
         sub { die {baz => 1} },                        # ignored
      )->({raw => 'FOO,BAR'});
   } ## end lives_ok
   'alternatives lives';

   is_deeply \@outcome,
     [{raw => 'FOO,BAR', structured => {foo => 'FOO', bar => 'BAR'}}],
     'outcome of alternatives'
     or diag Dumper \@outcome;
}

done_testing();
