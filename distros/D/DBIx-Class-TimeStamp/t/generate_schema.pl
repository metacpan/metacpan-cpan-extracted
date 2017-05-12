use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use DBIC::Test::Schema;

my $schema = DBIC::Test::Schema->connect('dbi:SQLite:t/foo.sqlite');
use Data::Dump qw/pp/;
print $_, ";\n" for $schema->deployment_statements;
unlink 't/foo.sqlite';
