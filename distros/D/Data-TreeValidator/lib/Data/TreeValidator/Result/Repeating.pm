package Data::TreeValidator::Result::Repeating;
{
  $Data::TreeValidator::Result::Repeating::VERSION = '0.04';
}
# ABSTRACT: Returns the result of processing a repeating branch
use Moose;
use namespace::autoclean;

use Data::TreeValidator::Types qw( Result );
use MooseX::Types::Moose qw( ArrayRef );

with 'Data::TreeValidator::Result';

has 'results' => (
    isa => ArrayRef[Result],
    traits => [ 'Array' ],
    handles => {
        results => 'elements',
        result_count => 'count',
    }
);

sub valid {
    my $self = shift;
    (grep { $_->valid } $self->results) == $self->result_count;
}

sub clean {
    my $self = shift;
    return [
        map  { $_->clean }
        grep { $_->valid }
        $self->results
    ];
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Result::Repeating - Returns the result of processing a repeating branch

=head1 DESCRIPTION

Contains the result of calling process on a
L<Data::TreeValidator::RepeatableBranch>

=head1 METHODS

=head2 results

Returns an array of all result objects (one for each time the branch was
repeated).

=head2 result_count

The amount of results processed

=head2 valid

Returns true if all result objects are valid

=head2 clean

Returns an array reference of all results, after calling C<clean> on them.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

