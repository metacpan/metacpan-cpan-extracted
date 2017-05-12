use t::Util;
use App::git::ship;

t::Util->goto_workdir('repository');

my $app = App::git::ship->new(silent => 1);
my $username = getpwuid $<;

delete $app->{repository};
$app->start;
is $app->repository, "https://github.com/$username/unknown", 'unknown repository';

delete $app->{repository};
system qw( git remote add origin https://github.com/harry-bix/mojo-MySQL5.git );
is $app->repository, 'https://github.com/harry-bix/mojo-MySQL5.git', 'http repository';

delete $app->{repository};
system qw( git remote rm origin );
system qw( git remote add origin git@github.com:bruce/some-cool-repo.git );
is $app->repository, 'https://github.com/bruce/some-cool-repo.git', 'http repository';

done_testing;
