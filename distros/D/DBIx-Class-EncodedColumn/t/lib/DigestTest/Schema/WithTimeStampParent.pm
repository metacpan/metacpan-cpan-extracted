package # hide from PAUSE
    DigestTest::Schema::WithTimeStampParent;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/EncodedColumn TimeStamp Core/);


1;
