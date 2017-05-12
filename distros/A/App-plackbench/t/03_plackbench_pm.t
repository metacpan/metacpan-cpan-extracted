use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw( $Bin );
my $psgi_path = "$Bin/test_app.psgi";

use App::plackbench;

subtest 'attribute'       => \&test_attributes;
subtest 'run'             => \&test_run;
subtest 'fixup'           => \&test_fixup;
subtest 'POST'            => \&test_post_data;
subtest 'warm'            => \&test_warm;
subtest 'fixup_from_file' => \&test_fixup_from_file;
done_testing();

sub test_attributes {
    my $bench = App::plackbench->new( psgi_path => $psgi_path );

    ok( !$bench->warm(), 'warm() should default to false' );

    $bench->warm(1);
    ok( $bench->warm(), 'warm() should be setable' );

    ok(
        App::plackbench->new( warm => 1 )->warm(),
        'warm() should be setable in the constructor'
    );

    ok( $bench->app(), 'lazy-built attributes should work' );

    return;
}

sub test_run {
    my $bench = App::plackbench->new(
        psgi_path => $psgi_path,
        count     => 5,
        uri       => '/ok',
    );
    my $stats = $bench->run();
    ok( $stats->isa('App::plackbench::Stats'),
        'run() should return App::plackbench::Stats object' );

    is( $stats->count(), $bench->count(),
        'the stats object should have the correct number of times' );

    cmp_ok( $stats->mean(), '<', 1,
        'the returned times should be within reason' );

    return;
}

sub test_fixup {
    my $counter = 0;

    my $bench = App::plackbench->new(
        psgi_path => $psgi_path,
        count     => 5,
        uri       => '/ok',
        fixup     => [
            sub {
                $counter++;
                shift->header( FooBar => '1.0' );
              }
        ],
    );

    $bench->run();
    is( $counter, 1, 'fixup subs should be called once per unique request' );
    is( $bench->app->_get_requests()->[-1]->{HTTP_FOOBAR},
        '1.0', 'changes made to the request should be kept' );

    $bench->fixup([{}]);
    eval { $bench->run(); };
    ok( !$@, 'should ignore non-coderefs and non-strings in fixup()' );

    return;
}

sub test_post_data {
    my $bench = App::plackbench->new(
        psgi_path => $psgi_path,
        count     => 5,
        uri       => '/ok',
        post_data => [ 'a', 'bb', 'ccc' ],
    );
    $bench->app()->_clear_requests();
    $bench->run();

    my @non_post = grep {
        $_->{REQUEST_METHOD} ne 'POST'
    } @{ $bench->app()->_get_requests() };
    ok(!@non_post, 'all requests should be POST requests when post data is specified');

    my @lengths = map { $_->{CONTENT_LENGTH} } @{ $bench->app()->_get_requests() };
    cmp_deeply(\@lengths,
        [1, 2, 3, 1, 2], 'should cycle through POST data in order');
    return;
}

sub test_warm {
    my $count = 5;
    my $bench = App::plackbench->new(
        psgi_path => $psgi_path,
        count     => $count,
        uri       => '/ok',
        warm      => 1,
    );
    $bench->app()->_clear_requests();
    my $stats = $bench->run();

    is($stats->count(), $count, 'should put as many requests into the stats as asked for');
    is(scalar(@{$bench->app()->_get_requests()}), $count + 1, 'should make an extra request when "warm" is enabled');

    $bench->warm(0);
    $bench->app()->_clear_requests();
    $stats = $bench->run();

    is($stats->count(), $count, 'should put as many requests into the stats as asked for');
    is(scalar(@{$bench->app()->_get_requests()}), $count, 'should not make an extra request when "warm" is disabled');

    return;
}

sub test_fixup_from_file {
    my $bench = App::plackbench->new(
        psgi_path => $psgi_path,
        uri       => '/ok',
    );

    ok($bench->run()->mean(), 'should run ok to begin with');

    $bench->add_fixup_from_file("$Bin/fail_redirect");

    eval {
        $bench->run();
    };
    like($@, qr/failed/, 'should eval the file and use it\'s sub');

    $bench->fixup(undef);
    $bench->add_fixup_from_file("$Bin/fail_redirect");
    is(Scalar::Util::reftype($bench->fixup()->[0]), 'CODE', 'should initialize fixup() if necessary');

    eval {
        $bench->add_fixup_from_file("$Bin/does_not_exist");
    };
    
    # Don't try and check that the error contains "No such file", cause that's
    # a different error in German (just sayin', it's not it came up or
    # anything...)
    ok($@, 'should die when file doesn\'t exist');

    eval {
        $bench->add_fixup_from_file("$Bin/syntax_error");
    };
    like($@, qr#\Q$Bin/syntax_error#, 'should die when file doesn\'t compile');

    eval {
        $bench->add_fixup_from_file("$Bin/non_sub");
    };
    like($@, qr/does not return a subroutine/, 'should die when file doesn\'t return a subroutine reference');

    return;
}
