package Data::Tabulate::Plugin::Fail;

use warnings;
use strict;

use Data::Dumper

# ABSTRACT: Test plugin for Data::Tabulate

our $VERSION = '0.01';

sub new{
    return bless {},shift;
}

sub test {
    my ($self,@data) = @_;
    
    Dumper( \@data );
}

1; # End of Data::Tabulate::Plugin::Test
