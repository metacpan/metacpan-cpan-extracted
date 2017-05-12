package TestCGIBinRoot3::Controller::CGIHandler;

use parent 'Catalyst::Controller::CGIBin';

__PACKAGE__->config(
        cgi_root_path => 'cgi',
        cgi_dir => TestCGIBinRoot3->path_to('root','cgi'),
       );


1;
