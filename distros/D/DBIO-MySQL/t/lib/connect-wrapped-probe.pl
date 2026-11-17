# Child of t/182-test-server-language.t: loads DBI, then the language hook, and
# says whether DBI::connect changed. A file, not -e '...', so that no quoting of
# a shell (cmd.exe on Windows knows no single quote) stands between the code and
# perl. Run from the root of the distribution with -It/lib.
use strict;
use warnings;
use DBI;
my $before = \&DBI::connect;
require DBIOMySQLTestLanguage;
print \&DBI::connect == $before ? 'same' : 'wrapped';
