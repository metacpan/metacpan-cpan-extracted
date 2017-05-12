use strict;

# vim: ft=perl ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Parser::parse_by_format');
ok __PACKAGE__->can('parse_by_format'), "summoned parse_by_format";

{
   my $input  = q{ Fo'o|  Ba"ar  |Ba\\az };
   my $parser = parse_by_format('foo|bar|baz');
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => " Fo'o",
      bar => '  Ba"ar  ',
      baz => 'Ba\\az '
     },
     'parse no trimming';
}

{
   my $input  = q{ Fo'o|  Ba"ar  |Ba\\az };
   my $parser = parse_by_format('foo|bar|baz', trim => 1,);
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => "Fo'o",
      bar => 'Ba"ar',
      baz => 'Ba\\az'
     },
     'parse with trimming';
}

{
   my $input  = q{ Fo'o|  Ba"ar  |Ba\\|az };
   my $parser = parse_by_format('foo|bar|baz', value => 'escaped');
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => " Fo'o",
      bar => '  Ba"ar  ',
      baz => 'Ba|az '
     },
     'parse with escaping, no trimming';
}

{
   my $input = q{ Fo'o|  Ba"ar  |Ba\\|az };
   my $parser =
     parse_by_format('foo|bar|baz', value => 'escaped', trim => 1,);
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => "Fo'o",
      bar => 'Ba"ar',
      baz => 'Ba|az'
     },
     'parse with escaping, with trimming';
}

{
   my $input  = q{" Fo'o"|"  Ba\\"ar  "|"Ba|az "};
   my $parser = parse_by_format('foo|bar|baz', value => 'double_quoted');
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => " Fo'o",
      bar => '  Ba"ar  ',
      baz => 'Ba|az '
     },
     'parse with double quoting';
}

{
   my $input  = q{' Foo'|'  Ba"ar  '|'Ba|az '};
   my $parser = parse_by_format('foo|bar|baz', value => 'single_quoted');
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => " Foo",
      bar => '  Ba"ar  ',
      baz => 'Ba|az '
     },
     'parse with single quoting';
}

{
   my $input  = q{ Foo|'  Ba"ar  '|'Ba|az '};
   my $parser = parse_by_format('foo|bar|baz',
      value => [qw< single_quoted whatever >]);
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => " Foo",
      bar => '  Ba"ar  ',
      baz => 'Ba|az '
     },
     'parse with single quoting and whatever';
}

{
   my $input  = q{ F\\|oo|"  Ba\"ar  "|'Ba|az '};
   my $parser = parse_by_format('foo|bar|baz',
      value => 'specials', trim => 1);
   my $record = $parser->({raw => $input});
   is_deeply $record->{structured},
     {
      foo => "F|oo",
      bar => '  Ba"ar  ',
      baz => 'Ba|az '
     },
     'parse with specials and trim';
}

{
   my $string = q<'FO;O';  BA\\;R  ;"BA\\"A;A\\"AZ">;
   my $parser = parse_by_format(
      'foo;bar;baz',
      value => [qw< single-quoted double-quoted escaped >],
      trim  => 1
   );
   my $record = $parser->({raw => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {
      structured => {foo => 'FO;O', bar => 'BA;R', baz => 'BA"A;A"AZ'},
      raw        => $string
     },
     'parsed by format, single-quoted, double-quoted, escaped, trim';
}

done_testing();
