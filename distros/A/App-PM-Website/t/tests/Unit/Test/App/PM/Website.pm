use strict;
use warnings;

package Unit::Test::App::PM::Website;
use base 'Test::Class';
use Test::More;
use App::Cmd::Tester;
use App::PM::Website;

#my $module_to_test = 'App::PM::Website';
#    use_ok( $module_to_test );
sub load_module : Test(startup=>1)
{
    use_ok( qw(App::PM::Website));
}

sub test_help : Tests()
{
    my $fixture = shift;

    my $obj = eval {App::PM::Website->new()};
    ok( defined $obj,"object is defined");
    is( $@, '', "no eval errors");

    my @test_argv = qw( help );
    my $expected_output_regex = qr/help/;
    my $result = App::Cmd::Tester->test_app('App::PM::Website' => \@test_argv );
    #my $result = App::Cmd::Tester->test_app( $obj, \@test_argv );
    is( $result->stderr, '', "stderr is blank");
    is( $result->error, undef, "threw no exceptions");
    like( $result->stdout, $expected_output_regex, "output is as expected" );
}

1;
