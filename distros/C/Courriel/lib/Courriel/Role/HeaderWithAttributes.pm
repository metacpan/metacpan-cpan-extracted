package Courriel::Role::HeaderWithAttributes;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Courriel::HeaderAttribute;
use Courriel::Helpers qw( parse_header_with_attributes );
use Courriel::Types qw( HashRef NonEmptyStr );
use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( blessed reftype );

use MooseX::Role::Parameterized;

parameter main_value_key => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter main_value_method => (
    isa => NonEmptyStr,
);

has _attributes => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => HashRef ['Courriel::HeaderAttribute'],
    init_arg => 'attributes',
    default  => sub { {} },
    handles  => {
        attributes      => 'elements',
        _attribute      => 'get',
        _set_attribute  => 'set',
        _has_attributes => 'count',
    },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $p = $class->$orig(@_);

    return $p
        unless $p->{attributes} && reftype( $p->{attributes} ) eq 'HASH';

    for my $name ( keys %{ $p->{attributes} } ) {
        my $lc_name = lc $name;
        $p->{attributes}{$lc_name} = delete $p->{attributes}{$name};

        next if blessed( $p->{attributes}{$lc_name} );

        $p->{attributes}{$lc_name} = Courriel::HeaderAttribute->new(
            name  => $name,
            value => $p->{attributes}{$name},
        );
    }

    return $p;
};

sub attribute {
    my $self = shift;
    my $key  = shift;

    return unless defined $key;

    return $self->_attribute( lc $key );
}

{
    my $validator = validation_for(
        params => [ { type => NonEmptyStr } ],
    );

    sub attribute_value {
        my $self = shift;
        my ($name) = $validator->(@_);

        my $attr = $self->attribute($name);

        return $attr ? $attr->value : undef;
    }
}

sub _attributes_as_string {
    my $self = shift;

    my $attr = $self->_attributes;

    return join '; ', map { $attr->{$_}->as_string } sort keys %{$attr};
}

{
    my $validator = validation_for(
        params => [
            name  => { type => NonEmptyStr, optional => 1 },
            value => { type => NonEmptyStr },
        ],
        named_to_list => 1,
    );

    role {
        my $p = shift;

        my $main_value_key = $p->main_value_key;

        method new_from_value => sub {
            my $class = shift;
            my ( $name, $value ) = $validator->(@_);

            my ( $main_value, $attributes )
                = parse_header_with_attributes($value);

            my %p = (
                value           => $value,
                $main_value_key => $main_value,
                attributes      => $attributes,
            );

            $p{name} = $name if defined $name;

            return $class->new(%p);
        };

        my $main_value_meth = $p->main_value_method || $p->main_value_key;

        method as_header_value => sub {
            my $self = shift;

            my $string = $self->$main_value_meth;

            if ( $self->_has_attributes ) {
                $string .= '; ';
                $string .= $self->_attributes_as_string;
            }

            return $string;
        };
    }
}

1;
