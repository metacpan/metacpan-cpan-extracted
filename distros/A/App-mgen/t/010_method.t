use strict;
use lib "../lib";
use Test::More;
use App::mgen;
use Scalar::Util qw/looks_like_number/;

subtest "generate test" => sub {
    @ARGV = qw/--dry-run Application::Module/;

    my $mgen = App::mgen->new;
    ok $mgen, "exist App::mgen";

    isnt looks_like_number($mgen->generate), "generate ok";
};

done_testing;
