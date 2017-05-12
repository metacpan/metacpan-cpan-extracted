use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;
use App::PM::Website;

use_ok( 'App::PM::Website' );

my $obj = eval {App::PM::Website->new()};
ok( defined $obj,"object is defined");
is( $@, '', "no eval errors");

my @test_argv = qw( help );
my $expected_output_regex = qr/help/;
my $result = App::Cmd::Tester->test_app( $obj , \@test_argv );
is( $result->stderr, '', "stderr is blank");
is( $result->error, undef, "threw no exceptions");
like( $result->stdout, $expected_output_regex, "output is as expected" );

done_testing();
