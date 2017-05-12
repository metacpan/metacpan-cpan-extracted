package Bb::Collaborate::Ultra::Session::Occurrence;
use warnings; use strict;
use Mouse;
use JSON;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;

=head1 NAME

Bb::Collaborate::Ultra::Session::Occurrence

=head1 DESCRIPTION

Session scheduling sub-record.

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Session>

=cut
    

coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->load_schema(<DATA>);
# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
{
    "type" : "object",
    "id" : "SessionOccurrence",
    "properties" : {
        "id" : {
            "type" : "string"
        },
        "startTime" : {
            "type" : "string",
            "format" : "DATE_TIME"
        },
        "active" : {
            "type" : "boolean"
        },
        "endTime" : {
            "type" : "string",
            "format" : "DATE_TIME"
        }
    }
}
