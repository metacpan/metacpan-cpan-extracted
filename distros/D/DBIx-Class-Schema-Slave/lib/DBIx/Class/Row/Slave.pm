package DBIx::Class::Row::Slave;

use base qw/ DBIx::Class /;

=head1 NAME

DBIx::Class::Row::Slave - L<DBIx::Class::Row> for slave B<(EXPERIMENTAL)>

=head1 SYNOPSIS

  # In your MyApp::Schema::Artist
  # Don't forget load this component
  __PACKAGE__->load_components( qw/ Row::Slave Core / );

  # Somewhere in your code
  use MyApp::Schema;

  # Connecting your Schema
  my $schema = MyApp::Schema->connect( @info );

  # Retrieving from master
  my $master = $schema->resultset('Artist')->find( $id );

  # Retrieving from slave
  my $slave  = $schema->resultset('Artist::Slave')->find( $id );

  # Adding in master
  # Complete normally
  my $master = $schema->resultset('Artist')->create( { ... } );

  # Adding in slave
  # You got an error!
  # DBIx::Class::ResultSet::create(): Can't insert via result source "Artist::Slave". This is slave connection.
  my $slave = $schema->resultset('Artist::Slave')->create( { ... } );

  # Also you can neither update nor delete via slave result_sources.
  my $slave = $schema->resultset('Artist::Slave')->single( { name => 'QURULI' } );
  $slave->name('RADIOHEAD');

  # DBIx::Class::Row::Slave::update(): Can't update via result source "Artist::Slave". This is slave connection.
  $slave->update;

  # DBIx::Class::Row::Slave::delete(): Can't delete via result source "Artist::Slave". This is slave connection.
  $slave->delete;

  
See L<DBIx::Class::Row>.

=head1 DESCRIPTION

DBIx::Class::Row::Slave is L<DBIx::Class::Row> for slave.
It provide no novel functions, but rather restrict some functions via slave C<result_source>s.
You can retrieve rows from either master or slave but you can neither add nor remove rows from slave.

=head1 METHODS

=head2 insert

Throw exception if called via slave C<result_source>s.

=cut

sub insert {
    my $self = shift;

    $self->throw_exception(
        "Can't insert via result source \"" . $self->result_source->source_name .
        "\". This is slave connection."
    ) if $self->is_slave;
    $self->next::method( @_ );
}

=head2 update

Throw exception if called via slave C<result_source>s.

=cut

sub update {
    my $self = shift;

    $self->throw_exception(
        "Can't update via result source \"" . $self->result_source->source_name .
        "\". This is slave connection."
    ) if $self->is_slave;
    $self->next::method( @_ );
}

=head2 delete

Throw exception if called via slave C<result_sources>s.

=cut

sub delete {
    my $self = shift;

    $self->throw_exception(
        "Can't delete via result source \"" . $self->result_source->source_name .
        "\". This is slave connection."
    ) if $self->is_slave;
    $self->next::method( @_ );
}

=head2 is_slave

=over 4

=item Return Value: 1 or 0

=back

This method returns C<1> if the row is retrieved via slave C<result_source>, otherwise returns C<0>.

  my $master = $schema->resultset('Artist')->find( $id );
  my $slave  = $schema->resultset('Artist::Slave')->find( $id );

  # Returns 0
  $master->is_slave;

  # Returns 1
  $slave->is_slave;

=cut

sub is_slave { $_[0]->_source_handle->schema->is_slave( $_[0]->result_source->source_name ) }

=head1 AUTHOR

travail C<travail@cabane.no-ip.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
