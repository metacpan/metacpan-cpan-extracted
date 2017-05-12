package DBIx::Class::InflateColumn::FS::ResultSet;
use base qw/DBIx::Class::ResultSet/;

=head1 NAME

DBIx::Class::InflateColumn::FS::ResultSet - FS columns resultset class

=head1 DESCRIPTION

Derive from this class if you intend to provide a custom resultset
class for result sources including L<DBIx::Class::InflateColumn::FS>
columns.

=head1 METHODS

=head2 delete

Delete associated file system storage for each row in a result set.

=cut

sub delete { shift->delete_all }

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
