package DBICx::Hooks;
BEGIN {
  $DBICx::Hooks::VERSION = '0.003';
}

# ABSTRACT: Provide hooks into DBIx::Class create()/update()/delete()

use strict;
use warnings;
use DBICx::Hooks::Registry;

sub insert {
  my $self = shift;
  my $ret  = $self->next::method(@_);

  $_->($self) for dbic_hooks_for($self, 'create');

  $ret;
}


sub update {
  my $self = shift;
  my $ret  = $self->next::method(@_);

  $_->($self) for dbic_hooks_for($self, 'update');

  $ret;
}


sub delete {
  my $self = shift;
  my $ret  = $self->next::method(@_);

  $_->($self) for dbic_hooks_for($self, 'delete');

  $ret;
}


1;


__END__
=pod

=head1 NAME

DBICx::Hooks - Provide hooks into DBIx::Class create()/update()/delete()

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ## On your DBIx::Class sources
    package Schema::Result::SourceName;
    use parent 'DBIx::Class::Core';
    
    __PACKAGE__->load_components('+DBICx::Hooks');
    
    
    ## Somewhere on your code
    use DBICx::Hooks::Registry;
    
    dbic_hooks_registry('Schema::Result::SourceName', 'create', sub {
      my ($new_row) = @_;
    
      ## your bussiness logic goes here
    });
    
    dbic_hooks_registry('Schema::Result::SourceName', 'update', sub {
      my ($updated_row) = @_;
    
      ## your bussiness logic goes here
    });

=head1 DESCRIPTION

This modules provides a way to hook into the create(), update(), and
delete() calls on your sources.

This can be used to trigger bussiness processes after one of this
operations.

You register callbacks (even multiple callbacks) with a pair
C<Source>/C<Action>. Each callback receives a single parameter, the row
object just created/updated/just deleted.

See L<DBICx::Hooks::Registry> for extra details on the
C<dbic_hooks_registry()> function.

=begin pod_coverage

=head2 insert

=head2 update

=head2 delete

=end pod_coverage

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0

=cut

