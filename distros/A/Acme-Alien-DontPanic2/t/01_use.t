use Test2::V0;
use Acme::Alien::DontPanic2 ();
use Text::ParseWords qw/shellwords/;

my @libs = shellwords( Acme::Alien::DontPanic2->libs );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'dontpanic', 'idenitified needed library' );

done_testing;
