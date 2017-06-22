use strict;
use File::Spec::Functions qw(catfile rel2abs);
use Test::More;

my $prowess = do(rel2abs(catfile 'script', 'prowess')) or die $@;
ok $prowess, 'compiled prowess';

is_deeply $prowess->parse_argv, {prove => [], watch => [qw( lib script t )]}, 'parse_argv';
is_deeply $prowess->parse_argv(qw( -w -w t )), {prove => ['-w'], watch => ['t']}, 'parse_argv';
is_deeply $prowess->parse_argv(qw( -l -w t -j6 )), {prove => [qw( -l -j6 )], watch => ['t']}, 'parse_argv';

done_testing;
