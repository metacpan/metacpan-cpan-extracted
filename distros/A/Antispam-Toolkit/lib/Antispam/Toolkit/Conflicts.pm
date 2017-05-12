package # hide from PAUSE
    Antispam::Toolkit::Conflicts;

use strict;
use warnings;

use Dist::CheckConflicts
    -dist      => 'Antispam::Toolkit',
    -conflicts => {
        'Antispam::httpBL' => '0.01',
    },

;

1;
