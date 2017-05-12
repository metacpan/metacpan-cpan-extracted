package Data::TreeValidator::Result::Branch;
{
  $Data::TreeValidator::Result::Branch::VERSION = '0.04';
}
# ABSTRACT: Contains the result of processing a branch
use Moose;
use namespace::autoclean;

use Data::TreeValidator::Types qw( Result );
use MooseX::Types::Moose qw( Str );
use MooseX::Types::Structured qw( Map );

with 'Data::TreeValidator::Result';

has 'results' => (
    isa => Map[Str, Result],
    traits => [ 'Hash' ],
    handles => {
        results => 'values',
        result_names => 'keys',
        result_count => 'count',
        result => 'get',
    }
);

sub valid {
    my $self = shift;
    ($self->errors == 0) &&
    (grep { $_->valid } $self->results) == $self->result_count;
}

sub clean {
    my $self = shift;
    return {
        map {
            $_ => $self->result($_)->clean
        } grep {
            $self->result($_)->valid
        } $self->result_names
    }
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Result::Branch - Contains the result of processing a branch

=head1 DESCRIPTION

This contains the result of processing a L<Data::TreeValidator::Branch>.

=head1 METHODS

=head2 results

Returns a list of all result values.

=head2 result_names

Returns a list of all child names that were processed

=head2 result_count

Returns the amount of child results this node directly has

=head2 result($name)

Fetch a result with a given name

=head2 valid

This result will be valid if all children are valid

=head2 clean

Clean data will be returned as a hash reference of result name to it's clean
data. If a result is not clean, it will not be included in the clean hash.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

