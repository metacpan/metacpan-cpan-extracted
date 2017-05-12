use Test::More;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki::Node::Item") or die("$@");
   };

my $c = 'Convert::Wiki::Node::Item';
can_ok ($c, qw/
  new
  as_wiki
  type
  /);

my $node = $c->new();
is (ref($node), $c);

is ($node->error(), '', 'no error yet');
is ($node->type(), 'item', 'type item');

is ($node->as_wiki(), "* \n", 'empty txt');

$node = $c->new( txt => 'Foo is a foo.' );
is ($node->as_wiki(), "* Foo is a foo.\n", 'Foo is a foo.');

