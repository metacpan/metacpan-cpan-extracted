use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Parser::parse_single');
ok __PACKAGE__->can('parse_single'), "summoned parse_single";

my $string = 'what=ever you=like whatever';
{
   my $parser = parse_single(key => 'mu');
   my $record = $parser->({raw => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {structured => {mu => $string}, raw => $string}, 'single was parsed';
}

{
   my $parser = parse_single(input => 'foo', output => 'bar', key => 'mu');
   my $record = $parser->({foo => $string});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {bar => {mu => $string}, foo => $string}, 'single was parsed';
}

done_testing();
