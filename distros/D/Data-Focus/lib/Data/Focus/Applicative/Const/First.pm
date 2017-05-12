package Data::Focus::Applicative::Const::First;
use strict;
use warnings;
use parent qw(Data::Focus::Applicative::Const);

my $PURE = __PACKAGE__->new(undef);

sub pure { $PURE }

sub build {
    my ($class, $builder, @f_parts) = @_;
    foreach my $f_part (@f_parts) {
        return $f_part if defined($f_part->get_const);
    }
    return $PURE;
}

sub create_part_mapper {
    my ($class) = @_;
    return sub { my ($datum) = @_; $class->new(\$datum) };
}

1;
__END__

=pod

=head1 NAME

Data::Focus::Applicative::Const::First - Const applicative functor with First monoid

=head1 DESCRIPTION

B<< Internal use only. >>

This functor accepts a scalar-ref or C<undef> as its value.

=head1 METHODS

See L<Data::Focus::Applicative::Const>.

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=cut
