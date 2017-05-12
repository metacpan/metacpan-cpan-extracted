use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Parser::parse_by_format');
ok __PACKAGE__->can('parse_by_format'), "summoned parse_by_format";

my $expected = {
   what => 'a',
   ever => 'b',
   you  => 'ccccccc',
   'do' => 'd',
};
for my $pair (
   ['what|ever|you|do', 'a|b|ccccccc|d'],
   ['what:ever;you/do', 'a:b;ccccccc/d'],
  )
{
   my ($format, $string) = @$pair;

   {
      my $parser = parse_by_format(format => $format);
      my $record = $parser->({raw => $string});
      is ref($record), 'HASH', 'record is a hash';
      is_deeply $record, {structured => $expected, raw => $string},
        'parsed by format';
   }

   {
      my $parser = parse_by_format(
         format => $format,
         input  => 'foo',
         output => 'bar'
      );
      my $record = $parser->({foo => $string});
      is ref($record), 'HASH', 'record is a hash';
      is_deeply $record, {bar => $expected, foo => $string},
        'parsed by format';
   }

   {
      my $parser = parse_by_format($format);
      my $record = $parser->({raw => $string});
      is ref($record), 'HASH', 'record is a hash';
      is_deeply $record, {structured => $expected, raw => $string},
        'parsed by format, straight unnamed parameter';
   }

   {
      my $parser = parse_by_format(
         $format,
         input  => 'foo',
         output => 'bar'
      );
      my $record = $parser->({foo => $string});
      is ref($record), 'HASH', 'record is a hash';
      is_deeply $record, {bar => $expected, foo => $string},
        'parsed by format, first parameter unnamed';
   }
} ## end for my $pair (['what|ever|you|do'...])

{
   my $string = 'FOO;BAR';
   my $parser = parse_by_format('foo;bar;rest');
   my $record = eval { $parser->({raw => $string}) };
   is $record, undef, 'no allow_missing, no party';
}

{
   my $string = 'FOO;BAR';
   my $parser = parse_by_format('foo;bar;rest', allow_missing => 1);
   my $record = $parser->({raw => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {
      structured => {foo => 'FOO', bar => 'BAR', rest => undef},
      raw        => $string
     },
     'parsed by format, allow_missing is 1';
}

done_testing();
