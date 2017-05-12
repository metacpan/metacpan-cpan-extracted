use lib 't/lib';

use Test::More;

BEGIN {
  use_ok 'Dallycot::Parser';
  use_ok 'Dallycot::AST';
  use_ok 'Dallycot::Value';
};

use ParserHelper;

test_parses(
  'cli:print' => [ fetch('cli', 'print') ],
);

done_testing();
