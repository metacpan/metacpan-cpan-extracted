use Test::Cmd;
use Test::More;

my $test = Test::Cmd->new(workdir => '', prog => 'blib/script/base64');
ok($test, 'Made Test::Cmd object');

is($test->run(args => 'decode', stdin => 'cGFja2FnZSBBcHA6OkJhc2U2NDs=') => 0, 'Test ran properly');
is($test->stdout => 'package App::Base64;', 'Execution gave the correct result');

done_testing;
