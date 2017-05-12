use Test::More;

use App::Kit;

diag("Testing detect() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok( !exists $app->{'detect'}, 'detect not set before called' );
isa_ok( $app->detect(), 'App::Kit::Obj::Detect' );
ok( exists $app->{'detect'}, 'detect set after called' );

my %meths = (
    is_web         => [qw(Web::Detect detect_web_fast)],
    is_interactive => [qw(IO::Interactive::Tiny is_interactive)],
    has_net        => [qw(Net::Detect detect_net)],
    is_testing     => [qw(Test::Detect detect_testing)],
);

for my $meth ( sort keys %meths ) {
    my $inc = $meths{$meth}[0] . ".pm";
    $inc =~ s{::}{/}g;

    my $lazy_test = 0;
    if ( exists $INC{$inc} ) {
        diag "$meth module already loaded, no lazy test can be done";
    }
    else {
        $lazy_test = 1;
    }

    no strict 'refs';    ## no critic
    my $func = "$meths{$meth}[0]\:\:$meths{$meth}[1]";
    is_deeply(
        [ $app->detect->$meth() ],
        [ $func->() ],
        "$meth() returns the same as its lazy under pinning"
    );

    if ($lazy_test) {
        ok( exists $INC{$inc}, "$meth module lazy loaded" );
    }
}

done_testing;
