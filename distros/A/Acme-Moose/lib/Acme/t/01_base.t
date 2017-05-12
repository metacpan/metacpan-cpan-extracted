#!perl -T

# Base Moose Test
use Acme::Moose; 
use Test::More tests => 27;
use Test::Moose::More;

#diag('Loading Moose and version');

my $moose = Acme::Moose->new; 
meta_ok($moose);

has_attribute_ok $moose,'foodage', "Can eat"  ;
has_attribute_ok $moose,'happiness',  "Can be happy"  ;
has_attribute_ok $moose,'tired',  "Can be sleepy"  ;

has_method_ok $moose, (qw(feed play nap sacrifice));
check_sugar_removed_ok $moose;

validate_class $moose => (
 
    attributes => [ qw(foodage happiness tired) ],
    methods    => [ qw(feed play nap sacrifice) ],
    isa        => [ 'Acme::Moose' ],
    # ensures $thing does not do these roles
    does_not   => [ 'Acme::Llama' ],
);