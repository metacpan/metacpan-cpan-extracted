use strict;
use Test::More tests => 1;

use App::CPANRepo;

my $app = App::CPANRepo->new;
my $repo = $app->resolve_repo('Plack');
is $repo, 'https://github.com/plack/Plack.git';

done_testing;
