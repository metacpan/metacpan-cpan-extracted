package Test::Serialize;

use FindBin;

use lib ("$FindBin::Bin/../lib");

use Moose;
use namespace::autoclean;

use Catalyst::Runtime '5.70';

use Catalyst;
use Test::Catalyst::Log;

__PACKAGE__->config(
    name => 'Test::Serialize',
);

__PACKAGE__->setup;
__PACKAGE__->log( Test::Catalyst::Log->new );

1;

