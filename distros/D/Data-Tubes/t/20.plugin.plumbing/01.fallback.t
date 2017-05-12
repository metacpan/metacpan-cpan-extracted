use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< pipeline summon >;

summon('Plumbing::fallback');
ok __PACKAGE__->can('fallback'), "summoned fallback";

{
   my @outcome;
   lives_ok {
      @outcome = fallback(
         sub { die 'foo' },
         sub { die ['bar'] },
         sub { die {baz => 1} },
         sub { return shift },
      )->('hey');
   } ## end lives_ok
   'tube exceptions are trapped';

   is scalar(@outcome), 1, 'first surviving tube run';
   is $outcome[0], 'hey', 'output record is fine';
}

{
   my (@outcome, @exceptions, @records);
   lives_ok {
      @outcome = fallback(
         sub { die "foo\n" },
         sub { die ['bar'] },
         sub { die {baz => 1} },
         sub { return shift },
         {
            catch => sub {
               push @exceptions, shift;
               push @records,    shift;
              }
         }
      )->('hey');
   } ## end lives_ok
   'tube exceptions are trapped';

   is scalar(@outcome), 1, 'first surviving tube run';
   is $outcome[0], 'hey', 'output record is fine';

   is scalar(@exceptions), 3, 'three exceptions thrown';
   is_deeply \@exceptions, ["foo\n", ['bar'], {baz => 1}],
     'catch receives exception';
   is_deeply \@records, [('hey') x 3], 'records are passed to catch';
}

{
   my (@outcome, @exceptions, @records);
   throws_ok {
      @outcome = fallback(
         sub { die "foo\n" },
         sub { die ['bar'] },
         sub { die {baz => 1} },
         sub { return shift },
         {
            catch => sub {
               push @exceptions, shift;
               push @records,    shift;
               die 'whatever' if @exceptions == 2;
              }
         }
      )->('hey');
   } ## end throws_ok
   qr{^whatever}, 'catch function can still throw exceptions';

   is scalar(@exceptions), 2, 'two exceptions thrown';
   is_deeply \@exceptions, ["foo\n", ['bar']], 'catch receives exception';
   is_deeply \@records, [('hey') x 2], 'records are passed to catch';
}

{
   my (@outcome, @exceptions, @records);
   lives_ok {
      @outcome = fallback(
         sub { die "foo\n" },
         sub { return shift },
         sub { die ['bar'] },
         sub { die {baz => 1} },
         {
            catch => sub {
               push @exceptions, shift;
               push @records,    shift;
              }
         }
      )->('hey');
   } ## end lives_ok
   'tube exceptions are trapped';

   is scalar(@outcome), 1, 'first surviving tube run';
   is $outcome[0], 'hey', 'output record is fine';

   is scalar(@exceptions), 1, 'one exceptions thrown, then success';
   is_deeply \@exceptions, ["foo\n"], 'catch receives exception';
   is_deeply \@records, [('hey') x 1], 'records are passed to catch';
}

{
   my (@outcome, @exceptions, @records);
   lives_ok {
      @outcome = fallback(
         sub { die "foo\n" },
         ['Parser::by_format', format => 'foo,bar'],
         sub { return shift->{raw} },
         sub { die ['bar'] },
         sub { die {baz => 1} },
         {
            catch => sub {
               push @exceptions, shift;
               push @records,    shift;
              }
         }
      )->({raw => 'hey'});
   } ## end lives_ok
   'tube exceptions are trapped';

   is scalar(@outcome), 1, 'first surviving tube run';
   is $outcome[0], 'hey', 'output record is fine';

   is scalar(@exceptions), 2, 'two exceptions thrown, then success';
   is_deeply \@exceptions,
     [
      "foo\n",
      {
         record => {raw => 'hey'},
         input  => 'raw',
         message =>
           "'parse by format': invalid record, expected 2 items, got 1",
      }
     ],
     'catch receives exception';
   is_deeply \@records, [({raw => 'hey'}) x 2],
     'records are passed to catch';
}

{
   my (@pre, @parsed, @post);
   my $counter  = 0;
   my $pipeline = pipeline(
      sub { return records => shift },
      sub { push @pre, ++$counter; return shift; },    # passthrough
      [
         'Plumbing::fallback',
         ['Parser::by_format', format => 'foo|bar'],
         ['Parser::by_format', format => 'foo,bar'],
         sub { return {invalid => shift->{raw}} },
      ],
      sub {
         push @parsed, shift;
         push @post,   $counter;
      },
      {tap => 'sink'}
   );

   lives_ok {
      $pipeline->(
         [{raw => 'FOO,BAR'}, {raw => 'FOO|BAR'}, {raw => 'unparsable'},]);
   }
   'pipeline survives parse errors';

   is_deeply \@pre, [1 .. 3], 'all records were parsed';
   is_deeply \@pre, [1 .. 3], 'all records were parsed (eventually)';
   is_deeply \@parsed,
     [
      {
         'structured' => {
            'foo' => 'FOO',
            'bar' => 'BAR'
         },
         'raw' => 'FOO,BAR'
      },
      {
         'raw'        => 'FOO|BAR',
         'structured' => {
            'foo' => 'FOO',
            'bar' => 'BAR'
         }
      },
      {
         'invalid' => 'unparsable'
      }
     ],
     'outcome of parsing';
}

done_testing();
