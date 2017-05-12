package Catalyst::Model::DBR;

use Moose;
use Carp;
extends 'Catalyst::Model';
has dbrconf  => ( is => 'ro', required => 1);
has dbr      => ( is => 'rw', isa => 'DBR' );
has schema_name => ( is => 'ro' );
has autoload_ok => ( is => 'rw' );

use DBR;
use DBR::Util::Logger;

our $VERSION = '1.0';
our $AUTOLOAD;

sub BUILD{
      my ($self) = @_;

      my $logger = new DBR::Util::Logger(-logpath => '/tmp/dbr_catalyst.log', -logLevel => 'debug2') or confess "Failed to create logger";

      my $dbr = new DBR(
			-logger => $logger,
			-conf   => $self->dbrconf,
		       ) or confess "Failed to create DBR";

      $self->dbr( $dbr );
      $self->autoload_ok( 0 ) unless $self->schema_name;
}

sub connect {
      my ($self,$schema_name) = @_;
      my $s = ($self->schema_name || $schema_name) or croak "Schema identifier is required";
      return $self->dbr->connect( $s ) or confess "Failed to connect to $s";
}

sub AUTOLOAD {
      my $self = shift;
      my $method = $AUTOLOAD;
      $self->autoload_ok or croak "Autoload is not allowed";

      my @params = @_;

      $method =~ s/.*:://;
      return unless $method =~ /[^A-Z]/; # skip DESTROY and all-cap methods

      my $dbr    = $self->dbr;
      my $inst   = $dbr    ->get_instance( $self->schema_name ) or confess "failed to retrieve instance for schema " .  $self->schema_name;
      my $schema = $inst   ->schema                             or croak ("Cannot autoload '$method' when no schema is defined");
      my $table  = $schema ->get_table   ( $method            ) or croak ("no such table '$method' exists in this schema");

      my $object = DBR::Interface::Object->new(
					       session  => $dbr->session,
					       instance => $inst,
					       table    => $table,
					      ) or confess('failed to create query object');

      return $object;
}

=pod

=head1 NAME

Catalyst::Model::DBR - DBR Model Class

=head1 SYNOPSIS


=head1 DESCRIPTION

This is the C<DBR> model class.

=head1 METHODS

=over 1

=item new

Initializes DBR object

=back

=head1 SEE ALSO

L<Catalyst>, L<DBR>

=head1 AUTHOR

Daniel, C<impious@cpan.org>

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
