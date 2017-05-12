package Data::Focus::Lens;
use strict;
use warnings;
use overload "." => sub {
    my ($self, $other, $swap) = @_;
    require Data::Focus::Lens::Composite;
    return Data::Focus::Lens::Composite->new(
        $swap ? ($other, $self) : ($self, $other)
    );
};

1;
__END__

=pod

=head1 NAME

Data::Focus::Lens - base class for lenses

=head1 DESCRIPTION

L<Data::Focus::Lens> is the base class for all lenses in L<Data::Focus> framework.

This class implements nothing except for operator overloads. See L</OVERLOADS> for detail.

=head1 ABSTRACT OBJECT METHODS

B<< This interface is experimental for now. You should not implement them by hand. Use L<Data::Focus::LensMaker> instead. >>

All lens implementations must implement the following methods.

=head2 $f_whole_after = $lens->apply_lens($applicative_class, $part_mapper, $whole_before)

Apply the C<$lens> and the C<$part_mapper> to C<$whole_before>, and obtain the result (C<$f_whole_after>).

C<$applicative_class> is the name of a L<Data::Focus::Applicative> subclass.
Generally speaking, it specifies the "context" in which this lens operation is performed.

C<$part_mapper> is a code-ref with the following signature.

    $f_part_after = $part_mapper->($part_before)

where C<$part_before> is a data part in C<$whole_before>.
The return value C<$f_part_after> is an object of C<$applicative_class>.
Calling C<< $part_mapper->($part_before) >> indicates that C<$lens> focuses on the C<$part_before>.

C<$whole_before> is the target data for the C<$lens>.

Return value C<$f_whole_after> is the result of applying the C<$lens> to C<$whole_before>,
wrapped in an object of C<$applicative_class>.

A typical implementation of C<apply_lens()> does the following.

=over

=item 1.

Extract data parts from C<$whole_before>. We call them as C<@parts> here.

=item 2.

Apply C<$part_mapper> to C<@parts>.

    @f_parts_after = map { $part_mapper->($_) } @parts

=item 3.

Collect all C<@f_parts_after> together to build the result. To unwrap L<Data::Focus::Applicative> wrappers of C<@f_parts_after>, we use C<build()> method.

    $f_whole_after = $applicative_class->build(sub {
        my (@parts_after) = @_;
        my $whole_after = ...;
        return $whole_after;
    }, @f_parts_after)

The callback passed to C<build()> method is supposed to set C<@parts_after> into the C<$whole_before> (whether or not it's destructive),
and return the C<$whole_after>.

=item 4.

Return C<$f_whole_after> obtained from C<build()> method.


=back

=head1 OVERLOADS

The C<"."> operator is overloaded. It means lens composition.

    $composite_lens = $lens1 . $lens2

See L<Data::Focus::Lens::Composite> for detail.

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=cut
