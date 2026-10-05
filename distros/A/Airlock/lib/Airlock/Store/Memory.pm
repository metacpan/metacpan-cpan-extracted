package Airlock::Store::Memory;

# ABSTRACT: In-process Airlock store for tests and single-process apps

use Moo;
use Carp qw( croak );
use namespace::autoclean;

our $VERSION = '0.001';


has _rows => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} }
);

has _pid => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { $$ }
);

# Rows written in one process are invisible to its siblings. Under a
# preforking server that shows up as codes that are randomly unknown, so it is
# refused outright.
sub _same_process {
  my ( $self ) = @_;
  croak __PACKAGE__.' is used in another process than the one that created it;'
    .' give Airlock a store that all processes share'
    unless $$ == $self->_pid;
  return;
}

sub insert {
  my ( $self, $row ) = @_;
  $self->_same_process;
  my $rows = $self->_rows;
  croak __PACKAGE__.'->insert needs a hash' unless defined $row->{hash};
  croak __PACKAGE__.'->insert duplicate hash' if exists $rows->{ $row->{hash} };
  croak __PACKAGE__.'->insert duplicate user_code'
    if defined $row->{user_code} && $self->find( 'user_code', $row->{user_code} );
  $rows->{ $row->{hash} } = { %$row };
  return 1;
}


sub find {
  my ( $self, $field, $value ) = @_;
  $self->_same_process;
  croak __PACKAGE__.'->find by '.$field.' is not supported'
    unless $field eq 'hash' || $field eq 'user_code';
  return unless defined $value;
  for my $row ( values %{ $self->_rows } ) {
    return { %$row } if defined $row->{$field} && $row->{$field} eq $value;
  }
  return;
}


sub update {
  my ( $self, $hash, $from_state, $changes ) = @_;
  $self->_same_process;
  my $row = $self->_rows->{$hash} or return 0;
  return 0 unless $row->{state} eq $from_state;
  for my $field ( keys %$changes ) {
    my $value = $changes->{$field};
    $row->{$field} = ref $value eq 'SCALAR' ? ( $row->{$field} // 0 ) + $$value : $value;
  }
  return 1;
}


sub purge {
  my ( $self, $before ) = @_;
  $self->_same_process;
  my $rows  = $self->_rows;
  my @stale = grep { $rows->{$_}{expires} < $before } keys %$rows;
  delete @{$rows}{@stale};
  return scalar @stale;
}


sub as_subs {
  my ( $self ) = @_;
  return {
    insert => sub { $self->insert(@_) },
    find   => sub { $self->find(@_) },
    update => sub { $self->update(@_) },
    purge  => sub { $self->purge(@_) }
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Store::Memory - In-process Airlock store for tests and single-process apps

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $memory  = Airlock::Store::Memory->new;
    my $airlock = Airlock->new( store => $memory->as_subs, ... );

=head1 DESCRIPTION

The store L<Airlock> uses when it is given none. Rows live in a hash inside the
process, so it is right for tests and for an app with exactly one process, and
wrong for anything that forks workers: used from another process than the one
that created it, it croaks.

It is also the reference for the store contract: four operations, of which
only L</update> has to be atomic.

=head2 insert

    $memory->insert( \%row );

Stores a copy of the row. Croaks when the C<hash> or a defined C<user_code> is
already taken.

=head2 find

    my $row = $memory->find( hash => $hash );
    my $row = $memory->find( user_code => 'BCDFGHJK' );

A copy of the matching row, or nothing.

=head2 update

    $memory->update( $hash, 'pending', { state => 'approved' } ) or return;

Applies the changes only if the row is still in C<$from_state>. Returns true
when it did. A value that is a reference to a number is added to the field
instead of replacing it: C<< { factor_failures => \1 } >>. This condition is what makes redeeming a request happen once.

=head2 purge

    my $removed = $memory->purge( time );

Removes every row whose C<expires> is before the given time.

=head2 as_subs

    my $store = $memory->as_subs;

The four operations as the hash of coderefs L<Airlock> takes as C<store>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-airlock/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
