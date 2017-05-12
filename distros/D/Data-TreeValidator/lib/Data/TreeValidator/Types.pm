package Data::TreeValidator::Types;
{
  $Data::TreeValidator::Types::VERSION = '0.04';
}
# ABSTRACT: Internal data types used by Data::TreeValidator
use MooseX::Types -declare => [qw(
    Constraint
    FlatMap
    Node
    NodeName
    Result
    HashTree
    Transformation
    Value
)];

use CGI::Expand qw( expand_hash );

use MooseX::Types::Moose
    qw( ArrayRef CodeRef Str Undef ),
    Value => { -as => 'MooseValue' };

use MooseX::Types::Structured qw( Dict Map );

subtype HashTree, as Map[
    NodeName, ArrayRef | Value | HashTree
];

subtype NodeName, as Str, where { /^[^\.]+$/ };

subtype FlatMap, as Map[ Str, Value ];

coerce HashTree, from FlatMap, via { expand_hash($_) };

role_type Node, { role => 'Data::TreeValidator::Node' };

role_type Result, { role => 'Data::TreeValidator::Result' };

subtype Value, as Undef | MooseValue;

subtype Constraint, as CodeRef;
subtype Transformation, as CodeRef;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Types - Internal data types used by Data::TreeValidator

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

