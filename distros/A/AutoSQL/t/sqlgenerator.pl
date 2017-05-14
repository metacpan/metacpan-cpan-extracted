use strict;
use lib 'lib', 't/lib';
use Test;
# BEGIN{ plan tests=>2;}

use AutoSQL::SQLGenerator;

use ContactSchema;
my $schema=ContactSchema->new;
sub _test_whole{
    my @sql = AutoSQL::SQLGenerator->generate_table_sql;
    print join "\n\n", @sql;
}

my $g=AutoSQL::SQLGenerator->new;

my @sql = AutoSQL::SQLGenerator->generate_table_sql($schema);
print join "\n\n", @sql;


