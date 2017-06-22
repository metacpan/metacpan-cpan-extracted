use lib '.';
use t::Util;
use App::git::ship;

t::Util->mock_git unless $ENV{GIT_REAL_BIN};
t::Util->test_git($ENV{GIT_REAL_BIN});

my $app = App::git::ship->new(silent => 1);

eval { $app->system(qw(git invalid command)) };
like $@, qr{git invalid command.*failed}, 'invalid command';

done_testing;
