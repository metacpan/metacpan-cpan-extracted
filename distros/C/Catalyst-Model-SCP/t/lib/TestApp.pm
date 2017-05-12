package TestApp;

use strict;
use warnings;

use Catalyst;

our $VERSION = '0.01';

__PACKAGE__->config( 'Model::MYSCP' => {
        host => '1.2.3.4',
        user => 'user',
        identity_file => 't/id_rsa',
        net_scp_options => {
            # Net::SCP::Expect options
        }
   }
);

__PACKAGE__->setup;

1;