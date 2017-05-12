package SQL::Translator::Filter::AutoCRUD::StorageEngine::DBIC::DynamicDefault;
{
  $SQL::Translator::Filter::AutoCRUD::StorageEngine::DBIC::DynamicDefault::VERSION = '2.143070';
}

# DBIx:Class extensions such as DBIx::Class::TimeStamp or
# DBIx::Class::DynamicDefault will set column values on create/update.
# This Filter makes those columns is_auto_increment so that AutoCRUD
# ignores the fields for create and update.

use strict;
use warnings;

use SQL::Translator::AutoCRUD::Utils;

sub filter {
    my ($sqlt, @args) = @_;
    my $schema = shift @args;

    foreach my $tbl_name ($schema->sources) {
        my $source = $schema->source($tbl_name);
        my $from = make_path($source);
        my $sqlt_tbl = $sqlt->get_table($from)
            or die "mismatched (dyn-update) table name between SQLT and DBIC: [$tbl_name]\n";

        my $columns_info = $source->columns_info;

        foreach my $field (keys %$columns_info) {
            next unless exists $columns_info->{$field}->{dynamic_default_on_create}
                or exists $columns_info->{$field}->{dynamic_default_on_update};

            $sqlt_tbl->get_field($field)->is_auto_increment(1);
        }
    }
}

1;
