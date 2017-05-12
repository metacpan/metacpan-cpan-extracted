use strict;
use Test::More;
use Acme::MetaSyntactic ();

my @themes =
    grep { eval "require $_;"; $_->has_remotelist() }
    map {"Acme::MetaSyntactic::$_"} Acme::MetaSyntactic->themes();
my $tests = 2 * @themes;

plan tests => $tests;

# allow testing only a few themes
# "dilbert viclones" will test ONLY those themes
# "not dilbert tmnt" will test ALL BUT those themes
my %test;
if ( @ARGV && $ARGV[0] eq 'not' ) {
    shift;
    %test = map { $_ => 1 } @themes;
    $test{"Acme::MetaSyntactic::$_"} = 0 for @ARGV;
}
else {
    %test =
          map { $_ => 1 } @ARGV
        ? map {"Acme::MetaSyntactic::$_"} @ARGV
        : @themes;
}

SKIP: {

    # this test must be explicitely requested
    skip "Set AMS_REMOTE environment variable to true to test up-to-dateness",
        $tests
        unless $ENV{AMS_REMOTE};

    # need LWP
    eval { require LWP::Simple; };
    skip "LWP::Simple required for testing up-to-dateness", $tests if $@;

    # need the network too
    skip "Network looks down - couldn't reach Google", $tests
        unless LWP::Simple::get( 'http://www.google.com/intl/en/' );

    # need Test::Differences
    eval { require Test::Differences; };
    my $has_test_diff = $@ eq '';

    # a little warning
    diag "Testing @{[scalar @themes]} themes using the network (may take a while)";

    # compare each theme data with the network
    for my $theme (@themes) {

    SKIP: {
            no warnings 'utf8';
            skip "$theme ignored upon request", 2 if !$test{$theme};
            my $current = [ sort $theme->name(0) ];
            my $online  = [ sort $theme->remote_list() ];

        SKIP: {
                skip "Fetching remote items for $theme probably failed", 2
                    if @$online == 0;

                # count
                is( scalar @$current,
                    scalar @$online,
                    "$theme has @{[scalar @$online]} items"
                );

                # details
                if( $has_test_diff ) {
                    Test::Differences::eq_or_diff(
                        $current, $online,
                        "$theme is up to date",
                        { context => 1 }
                    );
                }
                else {
                    is_deeply( $current, $online, "$theme is up to date" );
                }
            }
        }
    }
}
