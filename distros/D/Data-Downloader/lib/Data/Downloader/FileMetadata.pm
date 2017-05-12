=head1 NAME

Data::Downloader::FileMetadata;

=head1 DESCRIPTION

This is a essentially a materialized view, based on
L<Data::Downloader::MetadataPivot|Data::Downloader::MetadataPivot>.
This table is kept up to date along with the
metadatum table.

=head1 METHODS

=over

=cut

package Data::Downloader::FileMetadata;

use Log::Log4perl qw/:easy/;
use Data::Downloader::DB;
use base qw(Data::Downloader::DB::Object);

use strict;
use warnings;

=item rebuild_table

Re-create this table using the metadata_pivot view.

=cut

sub rebuild_table {
    my $class = shift;
    my $db = $class->init_db;

    # file_metadata is a materialized view, can always be rebuilt via :
    my $do_create = "create table file_metadata as select * from metadata_pivot";
    my $do_index  = "create unique index mp_file on file_metadata(file)";

    # It is kept up to date whenever metadatum is updated (see Feeds::refresh).
    DEBUG "Rebuilding file_metadata table";
    $db->dbh->do("drop table if exists file_metadata") or die $db->error;
    $db->dbh->do($do_create) or die $db->dbh->errstr;
    $db->dbh->do($do_index) or die $db->dbh->errstr;

}

=item do_setup

Set up this class.  This is done statically rather than
dynamically, since the materialized view doesn't have
enough information about the columns.

=cut

sub do_setup {
    my $self = shift;
    our $_made_foreign_keys;
    my $meta = $self->meta;
    $meta->table("file_metadata");
    $meta->setup(table => "file_metadata", columns => [file => { type => 'int', primary_key => 1, not_null => 1 } ]);
    for my $column (Data::Downloader::MetadataPivot->meta->columns) {
        next if $column eq "file";
        DEBUG "adding column $column";
        $meta->add_column($column);
    }
    unless ($_made_foreign_keys) {
        $_made_foreign_keys = 1;
        # This causes recursion when calling $file->file_metadata.
        # TODO: why?
        #$meta->add_foreign_keys(
        #    file => {
        #            class             => "Data::Downloader::File",
        #            key_columns       => { file => "id" },
        #            methods           => [ "get_set"],
        #            relationship_type => "one to one"
        #          },
        #      );
        Data::Downloader::File->meta->add_foreign_keys(
                file_metadata => {
                    class             => __PACKAGE__,
                    key_columns       => { id => "file" },
                    methods           => [ "get_set"],
                    relationship_type => "one to one",
                });
    }
    $meta->make_methods(replace_existing => 1);
    Data::Downloader::File->meta->make_methods(replace_existing => 1);
}

=back

=head1 SEE ALSO

L<Data::Downloader::MetadataPivot>

L<Data::Downloader/SCHEMA>

=cut

1;

