package Chemistry::OpenSMILES::Stereo::Tables;

# ABSTRACT: Stereochemistry tables
our $VERSION = '0.12.0'; # VERSION

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    @OH
    @TB
);

our @TB = (
    { axis => [ 1, 5 ], order => '@'  },
    { axis => [ 1, 5 ], order => '@@' },
    { axis => [ 1, 4 ], order => '@'  },
    { axis => [ 1, 4 ], order => '@@' },
    { axis => [ 1, 3 ], order => '@'  },
    { axis => [ 1, 3 ], order => '@@' },
    { axis => [ 1, 2 ], order => '@'  },
    { axis => [ 1, 2 ], order => '@@' },
    { axis => [ 2, 5 ], order => '@'  },
    { axis => [ 2, 4 ], order => '@'  },
    { axis => [ 2, 5 ], order => '@@' },
    { axis => [ 2, 4 ], order => '@@' },
    { axis => [ 2, 3 ], order => '@'  },
    { axis => [ 2, 3 ], order => '@@' },
    { axis => [ 3, 5 ], order => '@'  },
    { axis => [ 3, 4 ], order => '@'  },
    { axis => [ 4, 5 ], order => '@'  },
    { axis => [ 4, 5 ], order => '@@' },
    { axis => [ 3, 4 ], order => '@@' },
    { axis => [ 3, 5 ], order => '@@' },
);

our @OH = (
    { shape => 'U', axis => [ 1, 6 ], order =>  '@' },
    { shape => 'U', axis => [ 1, 6 ], order => '@@' },
    { shape => 'U', axis => [ 1, 5 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 6 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 5 ], order =>  '@' },
    { shape => 'U', axis => [ 1, 4 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 4 ], order =>  '@' },
    { shape => '4', axis => [ 1, 6 ], order => '@@' },
    { shape => '4', axis => [ 1, 5 ], order => '@@' },
    { shape => '4', axis => [ 1, 6 ], order =>  '@' },
    { shape => '4', axis => [ 1, 5 ], order =>  '@' },
    { shape => '4', axis => [ 1, 4 ], order => '@@' },
    { shape => '4', axis => [ 1, 4 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 6 ], order => '@@' },
    { shape => 'Z', axis => [ 1, 5 ], order => '@@' },
    { shape => 'U', axis => [ 1, 5 ], order => '@@' },
    { shape => 'Z', axis => [ 1, 4 ], order => '@@' },
    { shape => 'U', axis => [ 1, 4 ], order => '@@' },
    { shape => 'U', axis => [ 1, 3 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 3 ], order =>  '@' },
    { shape => '4', axis => [ 1, 3 ], order => '@@' },
    { shape => '4', axis => [ 1, 3 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 3 ], order => '@@' },
    { shape => 'U', axis => [ 1, 3 ], order => '@@' },
    { shape => 'U', axis => [ 1, 2 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 2 ], order =>  '@' },
    { shape => '4', axis => [ 1, 2 ], order => '@@' },
    { shape => '4', axis => [ 1, 2 ], order =>  '@' },
    { shape => 'Z', axis => [ 1, 2 ], order => '@@' },
    { shape => 'U', axis => [ 1, 2 ], order => '@@' },
);

1;
