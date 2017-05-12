package TestApp;
use Moose;
use FindBin;
extends 'Catalyst';

# use Catalyst::Runtime '5.80';

use Catalyst ( qw(-Log=error) );

__PACKAGE__->config(
    name => 'TestApp',
    home => "$FindBin::Bin",
);

__PACKAGE__->setup();

1;
