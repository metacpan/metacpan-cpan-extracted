use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# DBIO::Relationship::Codegen (karr k393): the column a proxy forwards to is
# a plain word. (The relationship name is set into the generated code as a
# string literal; Sub::Quote already refuses a name that is no sub name, so
# there is no input to test that with.)

{
  package CodegenQuoting::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(id => {}, parent_id => {}, title => {});
  __PACKAGE__->set_primary_key('id');
}

for my $bad ('a b', 'x;y', 'Foo::bar', '', "col\n",'a-b') {
  throws_ok {
    package CodegenQuoting::Proxied;
    our @ISA = ('DBIO::Core');
    CodegenQuoting::Proxied->proxy_to_related('child', { fwd => $bad });
  } qr/proxy column of relationship 'child' must be a plain column name/,
    "a proxy value of '$bad' is refused";
}

lives_ok {
  package CodegenQuoting::Proxied2;
  our @ISA = ('DBIO::Core');
  CodegenQuoting::Proxied2->proxy_to_related('child', { fwd => 'title', other => 'title_2' });
} 'word proxy values are accepted';

done_testing;
