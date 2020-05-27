package Data::AnyXfer::Role::Count;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Data::AnyXfer::Role::Count - role for counting transfers

=head1 SYNOPSIS

  package MyPackage;

  use Moo;
  use MooX::Types::MooseLike::Base qw(:all);

  extends 'Data::AnyXfer';

  ...

  around 'transform' => sub {
    my ( $orig, $self, $res ) = @_;
    ...
  };

  with 'Data::AnyXfer::Role::Count';

=head1 DESCRIPTION

This role counts transferred records.

Note that you I<must> include if after you have modified the
C<transform> method.

=head1 ATTRIBUTES

=head2 C<transfer_count>

This is the number of transferred records.

=cut

requires 'transform';

has 'transfer_count' => (
    is       => 'ro',
    isa      => Num,
    default  => 0,
    init_arg => undef,
);

sub _increment_transfer_count {
  ++$_[0]->{transfer_count};
}

=head1 METHODS

=head2 C<transform>

The C<transform> method is modified to increment the
L</transfer_count> when the returned record is not false.

=cut

around 'transform' => sub {
    my ( $orig, $self, $res ) = @_;

    my $rec = $self->$orig($res);

    $self->_increment_transfer_count() if $rec;

    return $rec;
};

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

