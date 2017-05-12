package Data::Deduper;
use strict;
use warnings;
our $VERSION = '0.03';

sub new {
    my $class = shift;
    my %args = ( @_ == 1 ? %{ $_[0] } : @_ );
    bless {
        data => \@{ $args{data} } || {},
        expr => $args{expr} || sub { my ( $a, $b ) = @_; $a eq $b },
        size => $args{size} || 10,
      },
      __PACKAGE__;
}

sub init {
    my $self  = shift;
    my @ret   = ( @_ == 1 ? @{ $_[0] } : @_ );
    my $count = @ret;
    my $size  = $self->{size};
    @ret = @ret[ ( $count - $size ) .. $count - 1 ] if $count > $size;
    @{ $self->{data} = \@ret };
}

sub dedup {
    my $self  = shift;
    my @newer = ( @_ == 1 ? @{ $_[0] } : @_ );
    my @data  = @{ $self->{data} };
    my @ret;
    for my $a (@newer) {
        next if grep { $self->{expr}( $_, $a ) } @data;
        push @data, $a;
        push @ret,  $a;
    }
    my $count = @data;
    my $size  = $self->{size};
    @data = @data[ ( $count - $size ) .. $count - 1 ] if $count > $size;
    $self->{data} = \@data;
    @ret;
}

sub data {
    my $self  = shift;
    @{ $self->{data} };
}

1;
__END__

=head1 NAME

Data::Deduper - remove duplicated item from array

=head1 SYNOPSIS

    use Data::Deduper;
    my @data = (1, 2, 3);
    my $dd = Data::Deduper->new(
        expr => sub { my ($a, $b) = @_; $a eq $b },
        size => 3,
        data => \@data,
    );
    # show only 4. because 4 is newer.
    for ($dd->dedup(3, 4)) {
        print $_;
    }
    # show 2 3 4 in whole items. max size of items is 3.
    for ($dd->data) {
        print $_;
    }

=head1 DESCRIPTION

Data::Deduper removes duplicated items in array. This is useful for fetching RSS/Atom feed continual.

=head1 INTERFACE

=head2 C<< Data::Deduper->new( expr => $expr, size => $size, data => $data ) >>

Creates a deduper instance.
$expr is specified as expr of grep. $size mean max size of array. $data is
initial array.

=head2 C<< $deduper->init( \@data ) >>

Reset items. return whole items.

=head2 C<< $deduper->deup( \@data ) >>

Dedup items. each item in @data will be checked whether is duplicate item. And if the item is not duplicated, it add to the items.
Return items added only. Note that return ignore duplicated items.

=head2 C<< $deduper->data() >>

Return whole items.

=head1 AUTHOR

Yasuhiro Matsumoto E<lt>mattn.jp@gmail.comE<gt>

=head1 SEE ALSO

L<XML::Feed::Deduper>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
