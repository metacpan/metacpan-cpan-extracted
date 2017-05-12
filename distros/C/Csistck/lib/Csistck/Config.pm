package Csistck::Config;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(option);

# Configuration options
my $Config = { };

sub option {
    my ($key, $value) = @_;

    # No key?
    return 0
      unless (defined $key);
    
    $Config->{$key} = $value
      if (defined $value);
    
    return $Config->{$key}; 
}

1;
