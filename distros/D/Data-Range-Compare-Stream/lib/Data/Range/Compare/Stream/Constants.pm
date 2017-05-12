package Data::Range::Compare::Stream::Constants;

require Exporter;

our @ISA=qw(Exporter);

use constant RANGE_START =>0;
use constant RANGE_END   =>1;
use constant RANGE_DATA  =>2;

our @EXPORT=qw(RANGE_START RANGE_END RANGE_DATA);

our @EXPORT_OK=@EXPORT;

1;
