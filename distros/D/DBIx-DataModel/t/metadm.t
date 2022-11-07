use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;

HR_connect;

my $schema = 'HR';

my @meta_tables    = $schema->metadm->tables;
my @db_table_names = sort map {$_->db_from} @meta_tables;
is_deeply \@db_table_names, [qw/T_Activity T_Department T_Employee/], "meta-tables";

my @assoc          = $schema->metadm->associations;
my @assoc_descr    = sort map {$_->path_AB->from->db_from . " => " . $_->path_AB->to->db_from} @assoc;
is_deeply \@assoc_descr, ['T_Department => T_Activity', 'T_Employee => T_Activity'], "associations";


my @emp_compoents = $schema->table('Employee')->metadm->components;
is_deeply \@emp_compoents, ['activities'], "component in composition";

my @activity_components = $schema->table('Activity')->metadm->components;
is_deeply \@activity_components, [], "composite in composition";

done_testing;




