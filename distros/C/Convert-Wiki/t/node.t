use Test::More;

BEGIN
   {
   plan tests => 28;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki::Node") or die("$@");
   };

my $c = 'Convert::Wiki::Node';
can_ok ($c, qw/
  new
  as_wiki
  _init
  error
  type
  link
  next
  prev
  _remove_me
  /);

my $node = $c->new();
is (ref($node), $c);

is ($node->error(), '', 'no error yet');

is ($node->error('Foo'), 'Foo', 'Foo error');
is ($node->error(''), '', 'no error again');

#############################################################################
# wrong node type

$node = $c->new ( txt => 'Foo', type => 'foo' );
like ($node->error(), qr/Node type must be one of.* but is 'Foo'/, 'Foo not valid type');

#############################################################################
# various node types

$node = $c->new ( txt => 'Foo', type => 'head1' );
is ($node->as_wiki(), "== Foo ==\n\n", '== Foo ==');

$node = $c->new ( txt => 'Foo is a foo.', type => 'paragraph' );
is ($node->as_wiki(), "Foo is a foo.\n\n", 'Foo is a foo.');

$node = $c->new ( txt => 'Foo is a foo.', type => 'mono' );
is ($node->as_wiki(), " Foo is a foo.\n\n", ' Foo is a foo.');

$node = $c->new ( txt => 'Foo is a foo.', type => 'item' );
is ($node->as_wiki(), "* Foo is a foo.\n", '* Foo is a foo.');

$node = $c->new ( type => 'line' );
is ($node->as_wiki(), "----\n\n", 'ruler');

#############################################################################
# node linking

$node = $c->new ( type => 'line' );
$next = $c->new ( type => 'para', txt => 'Chocolate chip.' );
$prev = $c->new ( type => 'head2', txt => 'Cookie' );

$node->link($next);

is ($node->prev(), undef, 'no previous');
is ($node->next(), $next, 'next');

is ($next->prev(), $node, 'node is previous');
is ($next->next(), undef, 'no next');

is ($prev->link($node), $prev, '$prev is previous');

is ($prev->prev(), undef, 'no previous');
is ($prev->next(), $node, 'node is next');

is ($node->prev(), $prev, 'prev is previous of node');
is ($node->next(), $next, 'next is next of node');

#############################################################################
# prev_by_type()

#  prev => node => next
# head2 => line => para

is ($node->prev_by_type('head'), $prev, 'previous headline');
is ($next->prev_by_type('head'), $prev, 'previous headline');

is ($next->prev_by_type('line'), $node, 'previous line');

is ($prev->prev_by_type('head'), undef, 'no previous headline');
is ($node->prev_by_type('para'), undef, 'no previous para');
is ($node->prev_by_type('line'), undef, 'no previous line');
is ($next->prev_by_type('mono'), undef, 'no previous mono');


