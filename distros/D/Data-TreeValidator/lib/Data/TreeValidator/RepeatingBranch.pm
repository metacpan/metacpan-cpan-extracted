package Data::TreeValidator::RepeatingBranch;
{
  $Data::TreeValidator::RepeatingBranch::VERSION = '0.04';
}
# ABSTRACT: A branch that can have its input repeated multiple times
use Moose;
use namespace::autoclean;

use Data::TreeValidator::Types qw( HashTree );

use aliased 'Data::TreeValidator::Result::Branch' => 'Result';
use aliased 'Data::TreeValidator::Result::Repeating' => 'RepeatingResult';

use MooseX::Params::Validate;
use MooseX::Types::Moose qw( ArrayRef Maybe );

with 'Data::TreeValidator::Node';
extends 'Data::TreeValidator::Branch';

sub process {
    my $self = shift;
    my ($tree) = pos_validated_list([ shift ],
        { isa => Maybe[ ArrayRef[HashTree] ], coerce => 1 }
    );
    my %args = @_;

    my $process = $tree || $args{initialize};

    return RepeatingResult->new(
        input => $tree,
        results => [
            map {
                my $element = $_;
                Result->new(
                    input => $element,
                    results => {
                        map {
                            $_ => $self->child($_)->process($element->{$_})
                        } $self->child_names
                    }
                )
            } @$process
        ]
    );
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::RepeatingBranch - A branch that can have its input repeated multiple times

=head1 DESCRIPTION

A repeatable branch is one that has a specification, and can consume input
multiple times. The branch can have any valid specification (including
repeatable elements).

This class has all the functionality of L<Data::TreeValidation::Branch>.

=head1 METHODS

=head2 process($input)

Takes an array reference as input, and attempts to validate each element against
the branch specification.

Returns a L<Data::TreeValidator::Result::Repeating> result object, which can be
inspected to determine if the processing was valid, and to obtain the cleaned
data (which will be wrapped as an array reference).

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

