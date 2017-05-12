# vim:ft=perl
package Foo;
use Test::More no_plan;
use base 'Class::Accessor::Assert';
__PACKAGE__->_mk_accessors("make_accessor", qw(a=ARRAY +b c=IO::File));

eval { my $x = Foo->new() };
like ($@, qr/Required member b not given to constructor/, 
    "Constructor needs to die on required fields");

eval { my $x = Foo->new({ b=> 1}) };
ok(!$@, "This required field can be anything");

eval { my $x = Foo->new({ b=> 1, a => {} }) };
like($@, qr/Member a needs to be of type ARRAY/, 
    "But a has to be an array");

# Now this is my usual trick
eval { my $x = Foo->new( a => [], b=> 1234 )};
like($@, qr/much like/, "Traps the non-hashref case");

# OK, let's finally get an object.
my $y = Foo->new({ a=>[], b=> 1234 });
# Now let's test setting

eval { $y->a("This is evidently not an array ref") };
like($@, qr/Member a needs to be of type ARRAY/, 
    "Can't set to prohibited type");

eval { $y->c("This is evidently not an IO::File") };
like($@, qr/Member c needs to be of type IO::File/, 
    "Can't set to prohibited type");

use IO::File;
eval { $y->c(IO::File->new) };
ok(!$@, "Can set to an allowed type");


1
