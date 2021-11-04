#!/usr/bin/env perl

use strict;
use warnings;

use App::Kramerius::V4;

# Arguments.
@ARGV = (
        'mzk',
        '224d66f8-f48e-4a92-b41e-87c88a076dc0',
);

# Run.
exit App::Kramerius::V4->new->run;

# Output like:
# Download http://kramerius.mzk.cz/search/api/v5.0/item/uuid:224d66f8-f48e-4a92-b41e-87c88a076dc0/streams
# Download http://kramerius.mzk.cz/search/api/v5.0/item/uuid:224d66f8-f48e-4a92-b41e-87c88a076dc0/full
# Save 224d66f8-f48e-4a92-b41e-87c88a076dc0.jpg