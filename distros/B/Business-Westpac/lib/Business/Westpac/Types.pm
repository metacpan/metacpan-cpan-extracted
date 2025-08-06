package Business::Westpac::Types;

=head1 NAME

Business::Westpac::Types

=head1 SYNOPSIS

    use Business::Westpac::Types qw/
        add_max_string_attribute
    /;

    has [ qw/
        funding_bsb_number
    / ] => (
        is       => 'ro',
        isa      => 'BSBNumber',
        required => 0,
    );

    ...

=head1 DESCRIPTION

Package for defining type constraints for use in the Business::Westpac
namespace.

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use DateTime::Format::DateParse; ## no critic
use Mojo::Util qw/ decamelize /;
use Exporter::Easy (
    OK => [ qw/
        add_max_string_attribute
    / ],
);

=head1 TYPES

=over

=item WestpacDate

A DateTime object, this will be coerced from the string DDMMYYYY

=cut

class_type 'DateTime';

subtype 'WestpacDate'
      => as 'DateTime';

coerce 'WestpacDate'
    => from 'Str'
    => via {
        my $date_str = $_;

        return $date_str if ref( $date_str );

        my ( $dd,$mm,$yyyy ) = ( $date_str =~ /^(\d{2})(\d{2})(\d{4})$/ );
        return DateTime::Format::DateParse->parse_datetime( "$yyyy-$mm-$dd" );
};

=item PositiveInt

An Int greater than zero

=cut

subtype 'PositiveInt'
	=> as 'Int'
	=> where { $_ > 0 }
	=> message { "The number provided, $_, was not positive" }
;

=item PositiveNum

A Num greater than zero

=cut

subtype 'PositiveNum'
	=> as 'Num'
	=> where { $_ > 0 }
	=> message { "The number provided, $_, was not positive" }
;

=item BSBNumber

A Str of the form C</^\d{3}-\d{3}$/>

=cut

subtype 'BSBNumber'
    => as 'Str',
    => where { $_ =~ /^\d{3}-\d{3}$/ }
	=> message { "The BSB provided, $_, does not match \\d{3}-\\d{3}" }
;

=back

=head1 METHODS

=head4 add_max_string_attribute

Helper method to allow easier definition of Str types that are limited
to a particular lengths. For example:


    __PACKAGE__->add_max_string_attribute(
        'RecipientNumber[20]'
        is       => 'ro',
        required => 0,
    );

Is equivalent to:

    subtype 'RecipientNumber'
        => as 'Maybe[Str]'
        => where {
            ! defined( $_ )
            or length( $_ ) <= 20
        }
        => message {
            "The string provided for recipient_number"
           . " was outside 1..20 chars"
        }
    ;

    __PACKAGE__->meta->add_attribute( 'recipient_number',
        isa       => 'RecipientNumber',
        predicate => "_has_recipient_number",
        is        => 'ro',
        required  => 0,
    );

=cut

sub add_max_string_attribute (
    $package,
    $name_spec,
    %attr_spec,
) {
    my ( $subtype_name,$max_length ) = ( $name_spec =~ /^(\w+)\[(\d+)\]$/ );
    my $attr_name = decamelize( $subtype_name );

    subtype $subtype_name
        => as 'Maybe[Str]'
        => where {
            ! defined( $_ )
            or length( $_ ) <= $max_length
        }
        => message {
            "The string provided for $attr_name"
           . " was outside 1..$max_length chars"
        }
    ;

    $package->meta->add_attribute( $attr_name,
        isa => $subtype_name,
        predicate => "_has_$attr_name",
        %attr_spec,
    );
}

1;
