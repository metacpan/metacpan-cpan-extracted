use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

my @functions = qw<
  parse_by_format
  parse_by_regex
  parse_by_separators
  parse_by_split
  parse_hashy
  parse_single
>;
summon([Parser => @functions]);
ok __PACKAGE__->can($_), "summoned $_" for @functions;

done_testing();
