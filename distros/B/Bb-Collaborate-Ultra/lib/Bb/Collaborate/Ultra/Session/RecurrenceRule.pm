package Bb::Collaborate::Ultra::Session::RecurrenceRule;
use warnings; use strict;
use Mouse;
use JSON;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;
coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
__PACKAGE__->load_schema(<DATA>);

=head1 NAME

Bb::Collaborate::Ultra::Session::RecurrenceRule

=head1 DESCRIPTION

Session scheduling sub-record.

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Session>

=cut
 
1;
# downloaded from https://xx-csa.bbcollab.com/documentation
 __DATA__
{
    "type" : "object",
    "id" : "RecurrenceRule",
    "properties" : {
        "recurrenceEndType" : {
	    "type" : "string",
	    "enum" : [ "on_date", "after_occurrences_count" ]
        },
        "daysOfTheWeek" : {
            "type" : "array",
            "items" : {
		"type" : "string",
		"enum" : [ "mo", "tu", "we", "th", "fr", "sa", "su" ]
            }
        },
        "recurrenceType" : {
            "type" : "string",
            "enum" : [ "daily", "weekly", "monthly" ]
        },
        "interval" : {
            "type" : "string",
            "enum" : [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" ]
        },
        "numberOfOccurrence" : {
            "type" : "integer"
        },
        "endDate" : {
            "type" : "string",
            "format" : "DATE_TIME"
        }
    }
}
