package TestApp;

use Moose 1.03;
use namespace::autoclean;

extends Catalyst => { -version => 5.80 };

__PACKAGE__->config( use_chained_args_0_special_case=>1 );
__PACKAGE__->setup;

1;
