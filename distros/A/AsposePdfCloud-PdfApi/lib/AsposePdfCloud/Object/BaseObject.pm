package AsposePdfCloud::Object::BaseObject;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON qw(decode_json);
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;


#
#
#
#NOTE: This class is auto generated by the swagger code generator program. Do not edit the class manually.
#


# return json string
sub to_hash {
    return decode_json(JSON->new->convert_blessed->encode( shift ));
}

# used by JSON for serialization
sub TO_JSON { 
    my $self = shift;
    my $_data = {};
    foreach my $_key (%{$self->get_attribute_map}) {
        if (defined $self->{$_key}) {
            $_data->{$self->get_attribute_map->{$_key}} = $self->{$_key};
        }
    }
    return $_data;
}

# from json string
sub from_hash {
    my ($self, $hash) = @_;
    # loop through attributes and use swagger_types to deserialize the data
    while ( my ($_key, $_type) = each %{$self->get_swagger_types }) {
        if ($_type =~ /^array\[/i) { # array
            my $_subclass = substr($_type, 6, -1);
            my @_array = ();
            foreach my $_element (@{$hash->{$self->get_attribute_map->{$_key}}}) {
                push @_array, $self->_deserialize($_subclass, $_element);
            }
            $self->{$_key} = \@_array;
        } elsif (defined $hash->{$_key}) { #hash(model), primitive, datetime
            $self->{$_key} = $self->_deserialize($_type, $hash->{$_key});
        } else {
            $log->debugf("warning: %s not defined\n", $_key);
        }
    }
  
    return $self;
}
  
# deserialize non-array data
sub _deserialize {
    my ($self, $type, $data) = @_;
    $log->debugf("deserializing %s with %s",Dumper($data), $type);
        
    if ($type eq 'DateTime') {
        return DateTime->from_epoch(epoch => str2time($data));
    } elsif ( grep( /^$type$/, ('int', 'double', 'string', 'boolean'))) {    		
        return $data;
    } else { # hash(model)
        my $_instance = use_module("AsposePdfCloud::Object::$type")->new;
        return $_instance->from_hash($data);
    }
}

1;
