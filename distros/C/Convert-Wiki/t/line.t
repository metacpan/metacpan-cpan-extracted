use Test::More;

BEGIN
   {
   plan tests => 6;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki::Node::Line") or die("$@");
   };

my $c = 'Convert::Wiki::Node::Line';
can_ok ($c, qw/
  new
  as_wiki
  type
  /);

my $node = $c->new();
is (ref($node), $c);

is ($node->error(), '', 'no error yet');
is ($node->type(), 'line', 'type line');

is ($node->as_wiki(), "----\n\n", 'line');

