package AsposePdfCloud::Object::Annotation;

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

use base "AsposePdfCloud::Object::BaseObject";

#
#
#
#NOTE: This class is auto generated by the swagger code generator program. Do not edit the class manually.
#

my $swagger_types = {
    'Color' => 'Color',
    'Contents' => 'string',
    'CreationDate' => 'string',
    'Subject' => 'string',
    'Title' => 'string',
    'Modified' => 'string',
    'Links' => 'ARRAY[Link]'
};

my $attribute_map = {
    'Color' => 'Color',
    'Contents' => 'Contents',
    'CreationDate' => 'CreationDate',
    'Subject' => 'Subject',
    'Title' => 'Title',
    'Modified' => 'Modified',
    'Links' => 'Links'
};

# new object
sub new { 
    my ($class, %args) = @_; 
    my $self = { 
        #
        'Color' => $args{'Color'}, 
        #
        'Contents' => $args{'Contents'}, 
        #
        'CreationDate' => $args{'CreationDate'}, 
        #
        'Subject' => $args{'Subject'}, 
        #
        'Title' => $args{'Title'}, 
        #
        'Modified' => $args{'Modified'}, 
        #
        'Links' => $args{'Links'}
    }; 

    return bless $self, $class; 
}  

# get swagger type of the attribute
sub get_swagger_types {
    return $swagger_types;
}

# get attribute mappping
sub get_attribute_map {
    return $attribute_map;
}

1;
