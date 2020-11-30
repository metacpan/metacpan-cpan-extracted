package DBIx::Class::StateMigrations::Migration::Routine;

use strict;
use warnings;

# ABSTRACT: Base class for an individual routine within a migration

use Moo;
use Types::Standard qw(:all);

use Scalar::Util 'blessed';

has 'Migration', is => 'ro', required => 1, isa => InstanceOf['DBIx::Class::StateMigrations::Migration'];

has 'routine_coderef', (
  is => 'ro', lazy => 1, 
  isa => CodeRef,
  default => sub { (shift)->_get_routine_coderef }
);


sub executed {
  my ($self, $set) = @_;
  $self->__executed(1) if ($set && ! $self->__executed);
  $self->__executed
}
has '__executed', is => 'rw', init_arg => undef, isa => Bool, default => sub { 0 };


sub _get_routine_coderef { ... }

sub BUILD {
  my $self = shift;
  $self->CodeRef
}


sub execute {
  my ($self, $db) = @_;
  
  die "already executed!" if ($self->executed);
  
  die "execute must be supplied connected DBIx::Class::Schema instance argument" 
    unless($db && blessed($db) && $db->isa('DBIx::Class::Schema'));
  
  die "Supplied schema object is not connected" unless ($db->storage->connected);
  
  my $ret = $self->routine_coderef->( $db, $self );
  $self->executed(1);
  return $ret;
}




1;

__END__

=head1 NAME

DBIx::Class::StateMigrations::Migration::Routine - Base class for an individual routine within a migration

=head1 DESCRIPTION

This should be subclassed and used used directly

=head1 CONFIGURATION


=head1 METHODS


=head1 SEE ALSO

=over

=item * 

L<DBIx::Class>

=item *

L<DBIx::Class::DeploymentHandler>

=item * 

L<DBIx::Class::Migrations>

=item * 

L<DBIx::Class::Schema::Versioned>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


