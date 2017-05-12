package Data::Validator::Role::Ordered;

=head1 NAME

Data::Validator::Role::Ordered - Provide results as a list in the order
specified.

=head1 SYNOPSIS

 use Data::Validator;

 sub test {
     state $arguments = Data::Validator->new(
        foo => "Str",
        bar => "Num",
     )->with(qw( Method Sequenced Ordered ));

     my ($self, $foo, $bar) = $arguments->validate(@_);
 }

=head1 DESCRIPTION

The Ordered Role adds to Data::Validator the ability for the `validate` method
to return an ordered list, with values matching the specification provided by
Data::Validator.

=cut

use strict;
use warnings FATAL => "all";
use Mouse::Role;

with qw( Data::Validator::Role::Sequenced );

=head1 MODIFIERS

=over 4

=item validate

Return a list, in order, of arguments rather than the result.

=cut

around validate => sub {
    my ($next, $self, @args) = @_;

    my $args = $self->$next(@args);

    return map $args->{$_->{name}}, @{ $self->rules };
};

=back

=head1 CONSIDERATIONS

Although it should be of nominal impact to performance, due to the constraints
of Data::Validator this first maps all provided parameters to a hash, validates
them as a hash, and then maps the has back to a list.  A more efficient method
would clearly to be use just a list from top to bottom.

=head1 BUGS

If you find any, feel free to submit them.

  https://github.com/ssmccoy/Data-Validator-Role-Ordered

=head1 LICENSE

Copyright © 2012, Say Media INC.
Released under the Artistic License, 2.0

=cut

1;
