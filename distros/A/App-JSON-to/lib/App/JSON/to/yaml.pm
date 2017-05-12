use strict;
use warnings;

package App::JSON::to::yaml;

our $VERSION = '1.000';

use YAML::Tiny ();


sub encoding
{
    'UTF-8'
}

sub dump
{
    YAML::Tiny->new($_[1])->write_string
}

1;
