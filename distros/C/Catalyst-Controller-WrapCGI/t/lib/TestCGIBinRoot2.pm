package TestCGIBinRoot2;

use Catalyst::Runtime '5.70';
use parent 'Catalyst';

__PACKAGE__->config({
    root => 'another_root',
    Controller::CGIHandler => {
        cgi_root_path => 'cgi',
        cgi_dir => 'cgi'
    }
});

__PACKAGE__->setup(qw/Static::Simple/);

1;
