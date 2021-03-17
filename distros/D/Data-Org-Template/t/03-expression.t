# OK, let's express a template!
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

$t = Data::Org::Template->new("Hello, [[name]]!");
$t->data_getter ({name => 'world'});
is ($t->text(), 'Hello, world!', 'basic template expression');

$t = Data::Org::Template->new("Hello, [[name]]!");
is ($t->text({name => 'world'}), 'Hello, world!', 'values at expression time');

$t = Data::Org::Template->new("Hello, {name}!", '{}');
is ($t->text({name => 'world'}), 'Hello, world!', 'values at expression time');




# Let's do an IF!
$t = Data::Org::Template->new (<<EOF);
Preface
[[.if flag]]
Yes!
[[..else]]
No...
[[..]]
Final text.
EOF
$t->data_getter ({flag => 1});
is_deeply ($t->transducers_requested(), ['if', 'lit']);
is ($t->text(), <<'EOF', 'if template');
Preface
Yes!
Final text.
EOF

$t->data_getter ({flag => 0});
is ($t->text(), <<'EOF', 'if template');
Preface
No...
Final text.
EOF


# And a with:
$t = Data::Org::Template->new (<<EOF);
[[.with context]]
Name: [[name]]
Title: [[title]]
[[..else]]
(no data)
[[..]]
EOF
is_deeply ($t->transducers_requested(), ['?', 'lit', 'with']);
$t->data_getter ({});
is ($t->text(), <<'EOF', 'with template');
(no data)
EOF

$t->data_getter ({
  context => {
     name => 'Bob',
     title => 'This is a title',
  },
});

is ($t->text(), <<'EOF', 'with template');
Name: Bob
Title: This is a title
EOF

$t = Data::Org::Template->new (<<EOF);
People:
[[.list people]]
- [[name]]
[[..else]]
(none listed)
[[..]]
EOF
$t->data_getter ({});
is ($t->text(), <<'EOF', 'with template, else case');
People:
(none listed)
EOF

$t->data_getter ({'people' => [{name => 'Bob'}, {name => 'Sam'}]});
is ($t->text(), <<'EOF', 'with template');
People:
- Bob
- Sam
EOF

$t = Data::Org::Template->new (<<EOF);
People:
[[.list people]][[name]][[..alt]], [[..]][[!nl]]
EOF
$t->data_getter ({'people' => [{name => 'Bob'}, {name => 'Sam'}]});
is ($t->text(), <<'EOF', 'with template');
People:
Bob, Sam
EOF
is_deeply ($t->transducers_requested(), ['?', 'list', 'lit', 'nl']);

# Last actual template: basically the same thing but with an iterator.
$t = Data::Org::Template->new (<<EOF);
People:
[[.list fullnames]]
- [[first]] [[last]]
[[..else]]
(none listed)
[[..]]
EOF
$t->data_getter ({'fullnames' => Iterator::Records->new([['Bob', 'Smith'], ['Sam', 'Johnson']], ['first', 'last'])});
is ($t->text(), <<'EOF', 'iterator through template');
People:
- Bob Smith
- Sam Johnson
EOF

# One more - same data, but demonstrating how to HTMLize an iterator into a table
$t = Data::Org::Template->new (<<EOF);
<table>
<tr><th>First name</th><th>Last name</th></tr>
[[.list fullnames]]
<tr><td>[[first|html]]</td><td>[[last|html]]</td></tr>
[[..else]]
<tr>
<td colspan="2">(none listed)</td>
</tr>
[[..]]
</table>
EOF
$t->data_getter ({'fullnames' => Iterator::Records->new([['Bob', 'Smith'], ['Sam', 'Johnson']], ['first', 'last'])});
is ($t->text(), <<'EOF', 'iterator to HTML table');
<table>
<tr><th>First name</th><th>Last name</th></tr>
<tr><td>Bob</td><td>Smith</td></tr>
<tr><td>Sam</td><td>Johnson</td></tr>
</table>
EOF


# Let's test an unknown transducer to make sure we croak
$t = Data::Org::Template->new (<<EOF);
People:
[[.first blah]]
[[..]]
EOF
is_deeply ($t->transducers_requested(), ['first', 'lit']);
ok (not eval { $t->text({}); }); 
like ($@, qr/Unknown transducer 'first' used in template/, 'error message identifies unknown transducer');

# 2021-03-16 - test the cookbook recipe that demonstrates dot-value expression (because the parser didn't handle it correctly).
$t = Data::Org::Template->new ("Value: [[.]]");
is ($t->text ('value'), "Value: value");

$t = Data::Org::Template->new ("Value: [[.|html]]");
is ($t->text ('value'), "Value: value");

done_testing();
