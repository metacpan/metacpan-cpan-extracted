#! perl

use strict;
use warnings;
use Test::More tests => 5;
sub throws_ok(&$;$);

use Data::Struct;

throws_ok {
  my $s = struct Foo => qw(foo bar);
} qr/Ambiguous/,
  'definition requires void';

throws_ok {
  struct "Foo";
} qr/Undefined struct 'Foo'/,
  'defined check';

struct Foo => qw(foo bar);

my $s = struct "Foo";
throws_ok {
  $s->foox
} qr/Unknown accessor 'foox'/,
  'accessor check';

throws_ok {
 my $s = struct Foo => { foox => 1} ;
} qr/Unknown accessor 'foox'/,
  'initial accessor check';

throws_ok {
  $s->foo(1);
} qr/Accessor 'foo' for struct 'Foo' takes no arguments/,
  'no-arg accessor check';

# Borrowed from Test::Exception.
sub throws_ok (&$;$) {
    my ( $coderef, $expecting, $description ) = @_;
    $description = "threw " . $expecting
    	unless defined $description;

    eval { $coderef->() };
    my $exception = $@;

    my $ok = $exception =~ m/$expecting/;
    ok( $ok, $description );
    unless ( $ok ) {
        diag( "expecting: " . $expecting );
        diag( "found: " . $exception );
    };
    $@ = $exception;
    return $ok;
}
