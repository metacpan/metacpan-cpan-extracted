use Test::More tests => 7;

BEGIN {
    use_ok('Acme::ChuckNorris');
}

diag("Testing Acme::ChuckNorris $Acme::ChuckNorris::VERSION");

ok( defined &round_house_kick_to_the_perl, 'round_house_kick_to_the_perl() imported' );
ok( defined &round_house_kick_to_the_text, 'round_house_kick_to_the_text() imported' );

my $chuck = round_house_kick_to_the_perl( \q{print "Ka POW"} );
if ( exists $ENV{'ROUND_HOUSE_KICK_TO_STDOUT'} && $ENV{'ROUND_HOUSE_KICK_TO_STDOUT'} ) {
    diag($chuck);
}
else {
    diag("Set \$ENV{'ROUND_HOUSE_KICK_TO_STDOUT'} to make this test really awesome!");
}

SKIP: {
    if ( eval 'require Test::Output; 1' ) {
        Test::Output::stdout_is( sub { eval round_house_kick_to_the_perl( \q{print "Ka POW"} ) }, "Ka POW", 'basic round_house_kick_to_the_perl()' );
        Test::Output::stdout_is( sub { eval round_house_kick_to_the_text( \q{Howdy} ) },          "Howdy",  'basic round_house_kick_to_the_text()' );
    }
    else {
        skip 'Please install Test::Output to run these tests', 2;
    }
}

my $codenorris = round_house_kick_to_the_perl( \q{print "Ka POW"}, 'Regex' => 0 );
my $_chuck = $chuck;
$_chuck =~ s/use\s+re\s+.eval.//;        # hack to allow this test to work in v5.18
$codenorris =~ s/use\s+re\s+.eval.//;    # hack to allow this test to work in v5.18
ok( $_chuck !~ m/eval/ && $codenorris =~ m/eval/, 'allowed arg override works' );
ok( round_house_kick_to_the_text( \q{Howdy}, 'Print' => 0 ), 'disallowed arg override has no effect' );
