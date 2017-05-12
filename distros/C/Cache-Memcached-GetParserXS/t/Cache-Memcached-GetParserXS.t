#!/usr/bi/perl

use Test::More tests => 6;
BEGIN { use_ok('Cache::Memcached::GetParserXS') };
use Data::Dumper;

my $fin;
my $p = new_parser();
ok($p, "Parser object was created");

# simple case
$p->t_parse_buf("VALUE foo 0 3
bar
END
");
is_deeply($fin, { foo => 0 }, "got foo");

# in chunks...
$p = new_parser();
$p->t_parse_buf("VALUE foo 0 3
bar
VALUE bar 1 3
baz
");
is($fin, undef, "nothing yet");
$p->t_parse_buf("END");
is($fin, undef, "nothing yet");
$p->t_parse_buf("\n");
is_deeply($fin, { foo => 0, bar => 1 }, "got 'em");


sub new_parser {
    $fin = undef;
    Cache::Memcached::GetParserXS->new({}, 0, sub { $fin = $_[0] });
}
