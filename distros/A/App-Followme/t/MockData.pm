package MockData;

use 5.008005;
use strict;
use warnings;
use integer;

use lib '../..';
use base qw(App::Followme::BaseData);

#----------------------------------------------------------------------
# Bless test data into a metadata class

sub new {
    my ($pkg, $data) = @_;

    my %self = %$data;
    $self{cache} = {};

    return bless(\%self, $pkg);
}

#----------------------------------------------------------------------
# Retrieve data when asked for it

sub fetch_data {
    my ($self, $name, $item, $loop) = @_;

    die "Missing metatadata: $name" unless exists $self->{$name};

    my %metadata = %$self;
    delete $metadata{cache};

    return %metadata;
}

1;
