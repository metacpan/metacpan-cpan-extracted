package AsposeBarCodeCloud::Object::Margins;

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

use base "AsposeBarCodeCloud::Object::BaseObject";

#
#
#
#NOTE: This class is auto generated by the swagger code generator program. Do not edit the class manually.
#

my $swagger_types = {
    'Left' => 'int',
    'Right' => 'int',
    'Top' => 'int',
    'Bottom' => 'int'
};

my $attribute_map = {
    'Left' => 'Left',
    'Right' => 'Right',
    'Top' => 'Top',
    'Bottom' => 'Bottom'
};

# new object
sub new { 
    my ($class, %args) = @_; 
    my $self = { 
        #
        'Left' => $args{'Left'}, 
        #
        'Right' => $args{'Right'},
         'Top' => $args{'Top'}, 
          'Bottom' => $args{'Bottom'}
         
        
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
