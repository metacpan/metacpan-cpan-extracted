use Test::More;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki::Node::Para") or die("$@");
   };

my $c = 'Convert::Wiki::Node::Para';
can_ok ($c, qw/
  new
  as_wiki
  type
  /);

my $node = $c->new();
is (ref($node), $c);

is ($node->error(), '', 'no error yet');
is ($node->type(), 'para', 'type para');

is ($node->as_wiki(), "\n\n", 'empty txt');

$node = $c->new( txt => 'Foo is a foo.' );
is ($node->as_wiki(), "Foo is a foo.\n\n", 'Foo is a foo.');

