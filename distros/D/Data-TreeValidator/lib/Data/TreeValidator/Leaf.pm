package Data::TreeValidator::Leaf;
{
  $Data::TreeValidator::Leaf::VERSION = '0.04';
}
# ABSTRACT: Represents a single leaf node in the validation tree specification
use Moose;
use namespace::autoclean;
use 5.10.0;

use Data::TreeValidator::Types qw( Constraint Transformation Value );
use MooseX::Types::Moose qw( ArrayRef CodeRef );

use aliased 'Data::TreeValidator::Result::Leaf' => 'Result';

use MooseX::Params::Validate;
use Try::Tiny;

with 'Data::TreeValidator::Node';

has 'constraints' => (
    isa => ArrayRef[Constraint],
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        constraints => 'elements',
        add_constraint => 'push',
    }
);

has 'transformations' => (
    isa => ArrayRef[Transformation],
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        transformations => 'elements',
        add_transformation => 'push',
    }
);

sub process {
    my $self = shift;
    my ($input) = pos_validated_list([ shift ],
        { isa => Value }
    );
    my %args = @_;

    my $process = $input // $args{initialize};

    my @errors;
    for my $constraint ($self->constraints) {
        if (is_CodeRef($constraint)) {
            try {
                $constraint->( $process );
            }
            catch {
                push @errors, $_;
            }
        }
    }

    my $clean;
    if (@errors == 0) {
        $clean = $process;
        for my $transformation ($self->transformations) {
            $clean = $transformation->( $clean );
        }
    }

    return Result->new(
        input => $input,
        errors => \@errors,
        @errors == 0 ? (clean => $clean) : ()
    );
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Leaf - Represents a single leaf node in the validation tree specification

=head1 DESCRIPTION

Represents a leaf in a tree, that is - a single atomic value. At some point all
branches will reduce to these nodes.

=head1 METHODS

=head2 constraints

Returns an array of all constraints for this leaf.

=head2 add_constraint

Adds a constraint to this leaf, at the end of the list

=head2 transformations

Returns an array of all transformations for this leaf.

=head2 add_transformation

Adds a transformation for this leaf, at the end of the list

=head2 process($input)

Takes $input, and matches it against all the constraints for this leaf. If they
all pass (that is, none throw exceptions), then C<$input> is passed through all
leaf transformations.

AT the end of processing, a L<Data::TreeValidator::Result::Leaf> object is
returned. This can be inspected to determine if validation was sucessful, and
obtain clean data.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

