#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
$Data::Dumper::Useqq = 1;

use Data::Org::Template;
use Iterator::Records;

my $t;

my $data = {name => 'world'};
$t = Data::Org::Template->new("Hello, [[name]]!");
$t->data_getter ($data);
is ($t->text(), 'Hello, world!', 'basic template expression');

$data->{name} = 'Bob';
is ($t->text(), 'Hello, Bob!', 'basic dynamic expression');

my $t2 = Data::Org::Template->new ("Current greeting: '[[greeting]]'");
$t2->data_getter ({greeting => sub { $t->text }});

is ($t2->text(), "Current greeting: 'Hello, Bob!'", 'magic value');
$data->{name} = 'Sam';
is ($t2->text(), "Current greeting: 'Hello, Sam!'", 'magic value after change');



done_testing();
