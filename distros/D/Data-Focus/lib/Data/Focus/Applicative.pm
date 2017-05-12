package Data::Focus::Applicative;
use strict;
use warnings;

1;
__END__

=pod

=head1 NAME

Data::Focus::Applicative - applicative functor spec for Data::Focus

=head1 DESCRIPTION

B<< This interface is experimental for now. You should not use them directly. >>

This class specifies the common interface for all applicative functors used in L<Data::Focus> distribution.

All applicative functors must inherit L<Data::Focus::Applicative>, and implement the following methods.


=head1 ABSTRACT CLASS METHODS

=head2 $f_result = $class->build($builder, @f_parts)

Build the C<$f_result> with C<$builder> and C<@f_parts>.

C<@f_parts> are zero or more L<Data::Focus::Applicative> objects. They must be instances of the C<$class>.
C<build()> method is the only interface where you can access raw data wrapped inside C<@f_parts>.

C<$builder> is a code-ref, which may be called zero or more times

    $result = $builder->(@parts)

where C<@parts> are the data inside C<@f_parts> applicative functors.

Return value C<$f_result> is an object of the C<$class>.
It wraps the C<$result>.

=head2 $f_result = $class->pure($result)

Wraps C<$result> with an wrapper object of C<$class>. This is equivalent to C<< $class->build(sub { $result }) >>.

=head2 $part_mapper = $class->create_part_mapper($updater)

B<< Internal use only. >>

Create the finest C<$part_mapper> for L<Data::Focus::Lens>.

C<$updater> is a code-ref. This code-ref is supposed to modify the finest part and return the result.
Subclasses may or may not use C<$updater> to create C<$part_mapper>.

=head1 RELATIONSHIP TO HASKELL

In pseudo-Haskell, C<build()> method is equivalent to

    build :: Applicative f => (b -> b -> ... -> t) -> [f b] -> f t
    build builder f_parts =
      case f_parts of
        [] -> pure builder  -- (builder :: t) in this case
        (p:ps) -> builder <$> p <*> (ps !! 0) <*> (ps !! 1) ...

I think this is the only pattern where applicative functors are used in Lens implementations.

The signature of C<create_part_mapper()> method is

    create_part_mapper :: Applicative f => (a -> b) -> (a -> f b)


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
