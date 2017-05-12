#!perl
# vim:enc=utf8:
use strict;
use warnings;

use Test::More;
use File::Temp;

my @pairs = map { [ split m{\n----\n}s ] } split m{%%%%\n}s,
    do { local $/, <DATA> };
plan tests => scalar @pairs;

$ENV{PERL5LIB}
    = join( ':', @INC ) . ( exists $ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : q{} );

my $test_program = <<'END_TEST_PROGRAM';
#!perl
use Acme::LAUTER::DEUTSCHER;
print <DATA>;
__DATA__
END_TEST_PROGRAM

foreach my $pair (@pairs) {
    my ( $english, $lauter ) = @$pair;

    my $outfile = File::Temp->new( UNLINK => 1, SUFFIX => '-lauter.pl' );
    print $outfile $test_program, "$english\n";
    $outfile->close;

    open my $infh, '-|', $^X, $outfile or die $!;
    my $result = do { local $/, <$infh> };
    close $infh;

    $english =~ s{\n}{\\n}gs;
    is $result, $lauter, "translated '$english'";
}

__DATA__
Timmy pet the cute puppy.
----
DIETER HAUSTIER DER NETTE WELPE!
%%%%
I ate a candle. Do you enjoy fish?
----
ICH Aß EINE KERZE! GENIEßEN SIE FISCHE?
%%%%
Please stop
yelling.
----
BITTE ANSCHLAG
KREISCHEN!
%%%%
test.test
----
TEST.TEST
%%%%
One.
Two.
----
EIN!
ZWEI!
