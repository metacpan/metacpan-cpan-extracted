use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Parser::parse_by_regex');
ok __PACKAGE__->can('parse_by_regex'), "summoned parse_by_regex";

my $expected = {
   what => 'ever',
   you  => 'like',
   to   => 'do',
};
my $string = '<<ever>> >like< "do"';
my $regex  = qr{(?mxs:
   \A
      <<(?<what>.*?)>> \s+
      >(?<you>.*?)< \s+
      "(?<to>.*?)"
   \z)};

{
   my $parser = parse_by_regex(regex => $regex);
   my $record = $parser->({raw => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record, {structured => $expected, raw => $string},
     'hash was parsed via regex';
}

{
   my $parser =
     parse_by_regex(regex => $regex, input => 'foo', output => 'bar');
   my $record = $parser->({foo => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record, {bar => $expected, foo => $string},
     'hash was parsed via regex';
}

{
   my $parser = parse_by_regex($regex);
   my $record = $parser->({raw => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record, {structured => $expected, raw => $string},
     'hash was parsed via regex, unnamed parameter';
}

{
   my $parser =
     parse_by_regex($regex, input => 'foo', output => 'bar');
   my $record = $parser->({foo => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record, {bar => $expected, foo => $string},
     'hash was parsed via regex, unnamed first parameter';
}

done_testing();
