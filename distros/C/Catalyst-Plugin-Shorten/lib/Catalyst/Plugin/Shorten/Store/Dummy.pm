package Catalyst::Plugin::Shorten::Store::Dummy;
use strict; use warnings;
our (%store, $i); BEGIN { $i = 0; }

sub shorten_get_data {
    my ( $c, $id ) = @_;
    $store{$id};
}

sub shorten_set_data {
    my $c = shift;
    my (%data) = @_;
    $store{++$i} = \%data;
        return $i;
}

sub shorten_delete_data {
    my ( $c, $id ) = @_;
    delete $store{$id};
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Shorten::Store::Dummy

=head1 SUBROUTINES/METHOS

=head2 shorten_get_data

=cut

=head2 shorten_set_data

=cut

=head2 shorten_delete_data

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=cut
