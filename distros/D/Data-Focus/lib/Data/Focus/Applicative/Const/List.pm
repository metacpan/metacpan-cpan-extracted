package Data::Focus::Applicative::Const::List;
use strict;
use warnings;
use parent qw(Data::Focus::Applicative::Const);

my $PURE = __PACKAGE__->new([]);

sub pure { $PURE }

sub build {
    my ($class, $builder, @f_parts) = @_;
    if(@f_parts == 0) {
        return $PURE;
    }elsif(@f_parts == 1) {
        return $f_parts[0];
    }else {
        return $class->new([map { @{$_->get_const} } @f_parts]);
    }
}

sub create_part_mapper {
    my ($class) = @_;
    return sub { $class->new([shift]) };
}


1;

__END__

=pod

=head1 NAME

Data::Focus::Applicative::Const::List - Const applicative functor with List monoid

=head1 DESCRIPTION

B<< Internal use only. >>

This functor accepts an array-ref as its value.

=head1 METHODS

See L<Data::Focus::Applicative::Const>.

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
