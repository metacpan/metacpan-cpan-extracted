package Articulate::Storage::DBIC::Simple::Schema;
use strict;
use warnings;

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

=head1 NAME

Articulate::Storage::DBIC::Simple::Schema

=head1 SYNOPSIS

  $schema->connect($dsn, $user, $password, $options);

This schema class extends L<DBIx::Class::Schema>; the schema has one resultset,
L<Articulate::Storage::DBIC::Simple::Schema::ResultSet::Articulate::Item>.

=head1 METHODS

=head3 connect_and_deploy

This convenience constructor performs a C<connect> (using the args provided) followed by a C<deploy> (with no args). It is useful for deploying in environments where you are sure that no previous schema exists (e.g. an in-memory database).

=head1 SEE ALSO

=over

=item * L<DBIx::Class::Schema>

=item * L<Articulate::Storage::DBIC::Simple>

=item * L<Articulate::Storage::DBIC::Simple::Schema::ResultSet::Articulate::Item>

=back

=cut

sub connect_and_deploy {
  my $package = shift;
  my $self    = $package->connect(@_);
  $self->deploy();
  return $self;
}

1;
