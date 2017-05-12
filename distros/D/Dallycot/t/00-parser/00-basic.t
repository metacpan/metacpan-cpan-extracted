use lib 't/lib';

use Test::More;

BEGIN {
  use_ok 'Dallycot::Parser';
  use_ok 'Dallycot::AST';
  use_ok 'Dallycot::Value';
};

use ParserHelper;

test_parses(
  "" => [Noop()],
  'ns:cli := "http://www.dallycot.net/ns/cli/1.0#"' => [
    nsdef('cli', stringLit('http://www.dallycot.net/ns/cli/1.0#'))
  ],
);

done_testing();
