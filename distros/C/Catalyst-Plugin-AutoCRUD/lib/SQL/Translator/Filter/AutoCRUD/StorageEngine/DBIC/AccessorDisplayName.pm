package SQL::Translator::Filter::AutoCRUD::StorageEngine::DBIC::AccessorDisplayName;
{
  $SQL::Translator::Filter::AutoCRUD::StorageEngine::DBIC::AccessorDisplayName::VERSION = '2.143070';
}

# Although AutoCRUD is "safe" for columns of any weird name you like,
# if the user has specified a DBIC Column accessor then it's nice
# to show that as the display name instead of the column's native name.

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
            or die "mismatched (accessor) table name between SQLT and DBIC: [$tbl_name]\n";

        my $columns_info = $source->columns_info;

        foreach my $field (keys %$columns_info) {
            next unless exists $columns_info->{$field}->{accessor}
                and $columns_info->{$field}->{accessor};

            $sqlt_tbl->get_field($field)->extra('display_name' =>
                make_label($columns_info->{$field}->{accessor}));
        }
    }
}

1;
