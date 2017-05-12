use Test::More;

BEGIN
   {
   plan tests => 8;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki::Node::Mono") or die("$@");
   };

my $c = 'Convert::Wiki::Node::Mono';
can_ok ($c, qw/
  new
  as_wiki
  type
  /);

my $node = $c->new();
is (ref($node), $c);

is ($node->error(), '', 'no error yet');
is ($node->type(), 'mono', 'type mono');

is ($node->as_wiki(), " \n\n", 'empty txt');

$node = $c->new( txt => 'Foo is a foo.' );
is ($node->as_wiki(), " Foo is a foo.\n\n", ' Foo is a foo.');

$node = $c->new( txt => "Foo is a foo.\nAnd Baz, too." );
is ($node->as_wiki(), " Foo is a foo.\n And Baz, too.\n\n", ' Baz, too.');

