use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Phrasebook;

my $book = Data::Phrasebook->new(class  => 'Plain',
                                 loader => 'ApacheFormat',
                                 file   => 't/02basic.conf',
                                );
ok($book, 'Data::Phrasebook->new() worked');

is($book->fetch('foo'), "I'm a foo.");

$book->dict('Bar');
is($book->fetch('foo'), "I'm a bar now.");

$book->dict(['Compound', 'Name']);
is($book->fetch('foo'), "I'm a compound foo now.");

is($book->fetch('tricky', { name => 'Sam'}), "My name is Sam and I'm tricky.");
