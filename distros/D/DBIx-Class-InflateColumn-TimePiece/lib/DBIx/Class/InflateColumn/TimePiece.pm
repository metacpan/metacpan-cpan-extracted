package DBIx::Class::InflateColumn::TimePiece;

# ABSTRACT: Auto-create Time::Piece objects from integer (number of seconds since epoch) columns

use v5.10;

use strict;
use warnings;

our $VERSION = '0.03'; # VERSION

use parent 'DBIx::Class';

use Time::Piece;

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method( $column, $info, @rest );

    my $data_type  = $info->{data_type}      || '';
    my $is_integer = $data_type eq 'integer' || $data_type eq 'int';

    return if !$info->{inflate_time_piece} || !$is_integer;

    $self->inflate_column(
        $column => {
            inflate => sub {
                my $dt = localtime shift;
                return $dt;
            },
            deflate => sub {
                return shift->epoch;
            },
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::TimePiece - Auto-create Time::Piece objects from integer (number of seconds since epoch) columns

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package Event;

    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components(qw/InflateColumn::TimePiece/);
    __PACKAGE__->table('my_events');
    __PACKAGE__->add_columns(
        event_name => {
            data_type => 'varchar',
            size      => 45,
        },
        event_created => {
            data_type          => 'integer',
            inflate_time_piece => 1,
        },
    );

    1;

In the above example, a L<DBIx::Class> named C<Event> is created, then L<this|DBIx::Class::InflateColumn::TimePiece>
DBIx::Class L<Component|DBIx::Class::Manual::Component> is loaded and two columns are added to the C<my_events> table.

A column with C<data_type> equal to C<integer> or C<int> and with property C<inflate_time_piece> set to true, will be
L<inflated|DBIx::Class::InflateColumn> using C<localtime> in L<Time::Piece> and L<deflated|DBIx::Class::InflateColumn>
using the L<epoch|Time::Piece> method.

=for Pod::Coverage register_column

=head1 SEE ALSO

=over 4

=item L<DBIx::Class::InflateColumn::DateTime>

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
