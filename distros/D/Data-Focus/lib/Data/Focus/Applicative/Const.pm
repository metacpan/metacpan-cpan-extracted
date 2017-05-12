package Data::Focus::Applicative::Const;
use strict;
use warnings;
use parent qw(Data::Focus::Applicative);

sub new {
    my ($class, $datum) = @_;
    return bless \$datum, $class;
}

sub get_const {
    return ${$_[0]};
}

1;
__END__

=pod

=head1 NAME

Data::Focus::Applicative::Const - Const applicative functor for Data::Focus

=head1 DESCRIPTION

B<< Internal use only. >>

A L<Data::Focus::Applicative> class for Haskell's L<Constant|http://hackage.haskell.org/package/transformers/docs/Data-Functor-Constant.html>
applicative functor.

This is an abstract class. It only implements C<new()> and C<get_const()>.
Subclasses must implement C<build()>, C<pure()> and C<create_part_mapper()>
based on the L<Monoid|http://hackage.haskell.org/package/base/docs/Data-Monoid.html> they choose.

=head1 CLASS METHODS

=head2 $f_datum = Data::Focus::Applicative::Const->new($datum)

The constuctor. The C<$f_datum> keeps C<$datum> inside.

=head1 OBJECT METHODS

=head2 $datum = $f_datum->get_const()

Get the C<$datum> passed in C<new()> method.

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=cut

