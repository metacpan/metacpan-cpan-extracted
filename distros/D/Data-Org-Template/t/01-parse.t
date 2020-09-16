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

# Test the parser a bit. These tests are taken straight from the prototype parser.
$t = Data::Org::Template->new("Hello, [[name]]!");
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', '!']], 'hello world');
#diag (Dumper($t->{template}));
$t = Data::Org::Template->new("Hello, {name}!", '{}');
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', '!']], 'delimiters');
$t = Data::Org::Template->new("Hello, :name:!", '::');
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', '!']], 'colon delimiters');
$t = Data::Org::Template->new("Hello, |name|!", '||');
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', '!']], 'bar delimiters');
$t = Data::Org::Template->new("Hello, joenamebob!", 'joe', 'bob');
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', '!']], 'stupid delimiters');

$t = Data::Org::Template->new("Hello,[[!nl]][[!nl]][[name]]!",);
is_deeply ($t->{template}, [['lit', 'Hello,'], ['nl'], ['nl'], ['?', 'name'], ['lit', '!']], 'bang directives');

$t = Data::Org::Template->new("Hello,[[!nl]][[!borg sql thing]][[name]]!",);
is_deeply ($t->{template}, [['lit', 'Hello,'], ['nl'], ['borg', 'sql thing'], ['?', 'name'], ['lit', '!']], 'bang directives');

# Test parser bypass.
$t = Data::Org::Template->new([['lit', 'Hello, '], ['?', 'name'], ['lit', '!']]);
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', '!']], 'bypass parser');

# A little more complexity in invocation.
$t = Data::Org::Template->new(<<EOF);
Hello, [[name]]!
Friend [[n2]] here.
EOF
#diag (Dumper($t->{template}));
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', "!\n"], ['lit', 'Friend '], ['?', 'n2'], ['lit', " here.\n"]], 'Multiline template');

$t = Data::Org::Template->new(<<EOF);
Hello, [[name]]!

Friend [[n2]] here.
EOF
#diag (Dumper($t->{template}));
is_deeply ($t->{template}, [['lit', 'Hello, '], ['?', 'name'], ['lit', "!\n"], ['lit', "\n"], ['lit', 'Friend '], ['?', 'n2'], ['lit', " here.\n"]], 'Multiline template w/blank');

$t = Data::Org::Template->new(<<EOF);
Preface
[[.if yes]]
Yes!
[[..else]]
No...
[[..]]
Final text.
EOF
#diag (Dumper($t->{template}));
is_deeply ($t->{template}, [['lit', "Preface\n"], ['if', 'yes', { '.' => ['.', undef, [['lit', "Yes!\n"]]], 'else' => ['else', undef, [['lit', "No...\n"]]] } ], ['lit', "Final text.\n"]], 'section with subsections');




done_testing();
