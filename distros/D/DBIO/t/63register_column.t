use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

lives_ok {
  DBIO::Test::Schema->load_classes('PunctuatedColumnName')
} 'registered columns with weird names';

done_testing;
