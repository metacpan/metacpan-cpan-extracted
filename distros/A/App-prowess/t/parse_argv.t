use strict;
use Test::More;
use File::Spec::Functions 'catfile';

my $prowess = do(catfile 'script', 'prowess') or die $@;
ok $prowess, 'compiled prowess';

is_deeply $prowess->parse_argv, {prove => [], watch => [qw( lib script t )]}, 'parse_argv';
is_deeply $prowess->parse_argv(qw( -w -w t )), {prove => ['-w'], watch => ['t']}, 'parse_argv';
is_deeply $prowess->parse_argv(qw( -l -w t -j6 )), {prove => [qw( -l -j6 )], watch => ['t']}, 'parse_argv';

done_testing;
