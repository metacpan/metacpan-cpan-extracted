package Chloro::Types::Internal;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use MooseX::Types -declare => [
    qw(
        ArrayOfFields
        Field
        HashOfFields
        Result
        )
];
use MooseX::Types::Moose qw( ArrayRef HashRef );

#<<<
class_type Field, { class => 'Chloro::Field'};

subtype ArrayOfFields,
    as ArrayRef[Field];

subtype HashOfFields,
    as HashRef[Field];

coerce HashOfFields,
    from ArrayOfFields,
    via {
        my $fields = $_;
        return { map { $_->name() => $_ } @{$fields} };
    };

role_type Result, { role => 'Chloro::Role::Result' };
#>>>

1;
