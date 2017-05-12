package DBX::Constants;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(DBX_CURSOR_RANDOM DBX_CURSOR_FORWARD);

use constant { DBX_CURSOR_RANDOM => 0, DBX_CURSOR_FORWARD => 1 };