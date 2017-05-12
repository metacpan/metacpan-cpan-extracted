=head1 NAME

Data::Downloader::MetadataPivot

=head1 DESCRIPTION

Represents a database view whose columns are
the possible types of metadata.

=cut

package Data::Downloader::MetadataPivot;

use Log::Log4perl qw/:easy/;
use Data::Downloader::DB;
use base qw(Data::Downloader::DB::Object);

use strict;
use warnings;

#
# TODO only recreate the view if the columns have changed.
#

sub _determine_columns {
    return map $_->name,
      @{ Data::Downloader::MetadataSource::Manager->get_metadata_sources };
}

=head1 METHODS

=over

=item rebuild_pivot_view

Rebuild the database view which is a pivoted version of the
metadata.  This will be called automatically whenever a repository
is saved.

=cut

sub rebuild_pivot_view {
    my $class = shift;
    my @columns = $class->_determine_columns;

    my $db = $class->init_db;
    my $sql = join "\n",
      "CREATE VIEW metadata_pivot as ",
      "select file ",
      ( join " ", map ", group_concat(case name when '$_' then value else null end) as $_ ", @columns ),
      " from metadatum m ",
      " group by file";

    my ($existing_sql) = $db->dbh->selectrow_array(
        q[select sql from sqlite_master where type='view' and name='metadata_pivot']
    );

    return if defined($existing_sql) && $existing_sql eq $sql;

    DEBUG "updating metadata pivot, metadata columns : @columns";
    $db->dbh->do("drop view if exists metadata_pivot") or die $db->dbh->errstr;
    $db->dbh->do($sql) or die $db->dbh->errstr;
}

=item do_setup

Set up this class.  If repositories are changed, this needs to
be called.

=cut

sub do_setup {
    my $self = shift;
    my $meta = $self->meta;

    $meta->table("metadata_pivot");
    $meta->setup(table => "metadata_pivot", columns => [file => { type => 'int', primary_key => 1 } ]);
    $meta->add_column($_) for $self->_determine_columns; # rose::db::sqlite can't do views

    #
    # Make the methods in this and the DD::File classes
    #
    $meta->make_methods(replace_existing => 1);
    Data::Downloader::File->meta->make_methods(replace_existing => 1);
}

=back

=head1 SEE ALSO

L<Rose::DB::Object>

perl -MData::Downloader::MetadataPivot -e 'print Data::Downloader::MetadataPivot->meta->perl_class_definition'

L<Data::Downloader/SCHEMA>

=cut

1;


