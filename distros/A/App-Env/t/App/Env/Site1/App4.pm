package App::Env::Site1::App4;

use strict;
use warnings;

sub alias { 
    return 'App3', { Alias => 'App4' } 
};

1;
