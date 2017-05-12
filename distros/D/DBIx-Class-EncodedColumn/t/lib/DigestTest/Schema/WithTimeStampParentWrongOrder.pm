package # hide from PAUSE
    DigestTest::Schema::WithTimeStampParentWrongOrder;

use strict;
use warnings;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/TimeStamp EncodedColumn Core/);

1;
