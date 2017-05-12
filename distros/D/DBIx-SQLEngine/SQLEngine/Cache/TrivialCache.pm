=head1 NAME

DBIx::SQLEngine::Cache::TrivialCache - Trivial Cache Object

=head1 SYNOPSIS

  use DBIx::SQLEngine::Cache::TrivialCache;

  $cache = DBIx::SQLEngine::Cache::TrivialCache->new();

  $cache->set( $key, $value );

  $value = $cache->get( $key );

  $cache->clear();

=head1 DESCRIPTION

This package provides a very, very simple cache implementation. 
No expiration or pruning is performed.

For a more full-featured cache, use one of the Cache::Cache classes.

=cut

package DBIx::SQLEngine::Cache::TrivialCache;

########################################################################

=head1 CACHE INTERFACE

=cut

########################################################################

=head2 Constructor

=over 4

=item new()

=back

=cut

sub new { my $class = shift; bless { @_ }, $class }

########################################################################

=head2 Accessors

=over 4

=item get_namespace()

Returns nothing.

=back

=cut

sub get_namespace { "Trivial" }

########################################################################

=head2 Operations

=over 4

=item get()

=item set()

=item clear()

=back

=cut

sub get { ($_[0])->{ $_[1] } }

sub set { ($_[0])->{ $_[1] } = $_[2] }

sub clear { %{ $_[0] } = () }

########################################################################

########################################################################

=head1 SEE ALSO

For a more full-featured cache, see L<Cache::Cache>.

For more about the Cache classes, see L<DBIx::SQLEngine::Record::Trait::Cache>.

For more about the Record classes, see L<DBIx::SQLEngine::Record::Class>.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
