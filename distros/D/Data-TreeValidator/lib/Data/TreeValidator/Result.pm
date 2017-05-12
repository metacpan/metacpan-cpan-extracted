package Data::TreeValidator::Result;
{
  $Data::TreeValidator::Result::VERSION = '0.04';
}
# ABSTRACT: Role specifying the result of processing
use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Moose qw( ArrayRef );

requires 'clean', 'valid';

has 'input' => (
    is => 'ro',
    required => 1
);

has 'errors' => (
    isa => ArrayRef,
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        errors => 'elements',
        error_count => 'count',
        add_error => 'push'
    }
);

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Result - Role specifying the result of processing

=head1 DESCRIPTION

This role is the basis for the result of processing a specification with some
input.

=head1 ATTRIBUTES

=head2 input

Gets the input that was passed in to process

=head1 METHODS

=head2 errors

Returns an array of errors that occured during processing. May be empty.

This array is only for errors directly assossciated with this node.

=head2 error_count

Returns the amount of errors that occured when processing this node.

=head2 clean

Should return the cleaned data. It is required to be implemented by consuming
classes

=head2 valid

Should return true or false depending on whether the input was valid input for
this node. Required to be implemented by consuming classes.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

