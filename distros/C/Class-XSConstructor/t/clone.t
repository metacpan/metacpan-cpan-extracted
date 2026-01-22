use Test::More;
use Class::XSConstructor ();

my $orig = { foo => [ 1, 2, 3 ], bar => qr/zzz/, baz => \1 };
my $clone = Class::XSConstructor::clone( $orig );

is_deeply( $orig, $clone );

push @{$orig->{foo}}, 4;

isnt( $clone->{foo}[-1], 4 );

done_testing;