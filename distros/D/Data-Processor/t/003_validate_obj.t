use strict;
use warnings;
use lib 'lib';
use Test::More;
use Data::Processor;


my $data = {
    some_key => 1,
};

my $schema = schema(Broken::Validator->new());

sub schema{
    my $validator_obj = shift;
    return {
        some_key => {
            validator   => $validator_obj,
            description => 'An object that knows how to validate our input',
        }
    };
}

eval { my $processor = Data::Processor->new($schema) };
ok ($@ =~ /validator object must implement method "validate/, $@);

$schema = schema(Good::Validator->new());
my $processor;
eval { $processor = Data::Processor->new($schema) };
ok (! $@);

my $error_collection = $processor->validate({some_key => 0});
my @errors = $error_collection->as_array();
ok (scalar(@errors)==1, '1 error found');
ok ($errors[0] =~ /The supplied value '0' was not 'true'/);

$error_collection = $processor->validate({some_key => 42});
@errors = $error_collection->as_array();
ok (scalar(@errors)==0, '0 error found');


# nested data
$schema = {
    top => {
        members => {
            %$schema
        }
    }
};

eval { $processor = Data::Processor->new($schema) };
ok (! $@);

$error_collection = $processor->validate({top => {some_key => 42}});
@errors = $error_collection->as_array();
ok (scalar(@errors)==0, '0 error found');

done_testing;


package Broken::Validator;
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

# This validator misses a "validate" method;


package Good::Validator;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub validate{
    my $self = shift;
    my $val = shift;

    # Do interesting stuff, here.

    # We need to return undef if we successfully validated.
    return $val ? undef: "The supplied value '$val' was not 'true'";
}

1
