package Data::TreeValidator;
{
  $Data::TreeValidator::VERSION = '0.04';
}
# ABSTRACT: Easy validation and transformation of scalar tree structures
use strict;
use warnings;
1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator - Easy validation and transformation of scalar tree structures

=head1 SYNOPSIS

    use Data::TreeValidator::Sugar qw( branch leaf );
    use Data::TreeValidator::Constraints qw( required );

    my $validator = branch {
        name => branch {
            first_name => leaf( constraints => [ required ] ),
            last_name => leaf( constraints => [ required ] ),
        },
        age => leaf
    };

    my $result = $validator->process({
        name => {
            first_name => 'Oliver',
            last_name => 'Charles',
        },
        age => 21
    });

    my $clean = $result->clean;
    Person->insert($clean);

=head1 DESCRIPTION

There exist a plethora of form libraries on CPAN, but this takes a different
approach. Data::TreeValidator takes the extremely simplistic approach that a
form is nothing more than a tree, that is given questionable data. The process
of validating a form can be thought of in 2 stages: constraints and
transformations.

=head2 Constraints

Constraints constraint data to match certain values. In the synopsis above, the
required constraint is applied to the C<first_name> and C<last_name> nodes,
meaning that these must be passed a true string (not C<undef>, and not an empty
string) in order to be valid.

Constraints can do a lot more than this however, as a constraint is just a
function. You could pass a function that verifies something is an integer,
another than verifies that the integers are within bounds, and another that is
closure with access to your database handle, in order to guarantee uniqueness of
an attribute.

Constraints are chained and applied in order.

=head2 Transformations

After all constraints pass, the input data is then chained through a series of
transformations. Transformations allow to ensure you get data back in a
consistent for you expect. For example, you could apply transformations on a
text input to make sure it has no leading or trailing whitespace, then another
to ensure that the string is in Title Case.

Transformations are essentially mapping functions, which take data of one type,
and return data in another type (which may, or may not be the same).

Transformations are also applied in order, and all transformations are composed
together, so that input flows from one into the next.

=head1 IMPORTANT DOCUMENTATION

You will probably be most intrested in the following documentation:

=over 4

=item L<Data::TreeValidator::Branch>, L<Data::TreeValidator::Leaf>

The essentials for specifying the structure of your validation tree.

=item L<Data::TreeValidator::RepeatingBranch>

A branch that can repeat it's input

=item L<Data::TreeValidator::Constraints>, L<Data::TreeValidator::Transformations>

Useful constraints and transformations you may wish to make use of.

=item L<Data::TreeValidator::Sugar>

Syntatic sugar to ease the creation of validation specifications.

=back

=head1 WHY?

Why do we need another way to validate data? I have a few presonal issues with
the philosophy behind the other form libraries on CPAN.

=over 4

=item Mixed responsibility

I do not think it is the form validations responsibility to handle the view of
the form itself. A form, in my eyes, should be a specification for how to
constrain data, and how to transform it. It is not a system for saying how the
HTML should look.

This is not to say I'm against helpers to perform rendering a view to input
data, I just do not believe it should be part of the same distribution.

=item Over specialization

LIkewise, most of the form systems seem to be overly specializing, with field
types that map to HTML input controls. I suppose in practice, this makes sense,
but again - the form system does not have to be matched to HTML, it should be a
level above that. Furthermore, most of the problems I've ran into with form
systems have required a change to the form system itself, and have not been
something I can fix. I like to think that the architecture
C<Data::TreeValidator> has can extend to most circumstances, but time will tell.

=item Excessive state

A validator in C<Data::TreeValidator> is fundamentally immutable. The act of
calling C<process> creates a special result object that takes the given input,
and an optional given initialization object, but does not change state as a
result of the call. This is a huge advantage in my opinion, as it allows us to
fully cache a form at application startup, rather than generating them on
request.

Other form libraries do allow this, to an extent, but I've found them limiting.
Once I start extending form with my own parameters, I've found it very difficult
to inject these at the time of processing, rather than the point of
instantiation. Data::TreeValidator takes a different approach where you pass in
extra parameters at process time, not construction.

=back

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

