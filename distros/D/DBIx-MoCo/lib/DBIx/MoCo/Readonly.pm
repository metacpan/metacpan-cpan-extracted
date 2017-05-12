package DBIx::MoCo::Readonly;
use strict;
use Carp;
use base qw(DBIx::MoCo);

sub create { croak "Can't create into readonly class ", shift }
sub delete { croak "Can't delete from readonly class ", shift }
sub delete_all { croak "Can't delete from readonly class ", shift }
sub save { croak "Can't save into readonly class ", shift }

sub param {
    my $self = shift;
    croak "Can't change params for readonly class ", $self if $_[1];
    $self->{$_[0]};
}

1;

=head1 NAME

DBIx::MoCo::Readonly - Base class for read-only DBIx::MoCo classes.

=head1 SYNOPSIS

  package NeverChangeModel;
  use base qw(DBIx::MoCo);

  __PACKAGE__->db_object('NeverChangeDataBase');
  __PACKAGE__->table('user');
  __PACKAGE__->primary_keys(['user_id']);

  1;

=head1 SEE ALSO

L<DBIx::MoCo>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
