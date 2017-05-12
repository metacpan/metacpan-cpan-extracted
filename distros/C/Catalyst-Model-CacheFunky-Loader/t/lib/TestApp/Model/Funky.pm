package TestApp::Model::Funky;

use strict;
use warnings;
use base qw/Catalyst::Model::CacheFunky::Loader/;

__PACKAGE__->config(
        class            => 'TestApp::Funky', 
        initialize_info  => { 'Storage::Simple' => {} } ,
        );

1;



