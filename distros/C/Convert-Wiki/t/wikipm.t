use Test::More;

BEGIN
   {
   plan tests => 13;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Convert::Wiki") or die($@);
   };

can_ok ("Convert::Wiki", qw/
  new
  clear
  from_txt
  as_wiki
  error
  debug
  nodes
  /);

#############################################################################
my $wiki = Convert::Wiki->new();

is (ref($wiki), 'Convert::Wiki');

is ($wiki->error(), '', 'no error yet');
is ($wiki->error('Foo'), 'Foo', 'Foo error');
is ($wiki->error(''), '', 'no error again');

is ($wiki->nodes(), 0, 'none yet');

#############################################################################
# debug mode

$wiki = Convert::Wiki->new( debug => 1 );

is ($wiki->debug(), 1, 'debug mode');

#############################################################################
# interlink option

$wiki = Convert::Wiki->new( interlink => [ 'foo', 'bar baz' ] );
is ($wiki->error(), '', 'interlink with list');

#############################################################################
# wrong options

$wiki = Convert::Wiki->new( ddebug => 1 );
like ($wiki->error(), qr/Unknown option 'ddebug'/, 'unknown option ddebug');

$wiki = Convert::Wiki->new( interlink => 1 );
like ($wiki->error(), qr/interlink.*needs a list of/, 'interlink needs list');

#############################################################################
# convert from_txt

my $txt = <<HERE

Headline
===============

 - bullet one
 - bullet two

Some text in a paragraph. and some more and more and more.

HERE
;

$wiki = Convert::Wiki->new( );

is ($wiki->from_txt($txt), $wiki, 'from_txt');

is ($wiki->nodes(), 4, '4 nodes');

