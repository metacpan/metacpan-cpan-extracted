package TestCGIBin;

use Catalyst::Runtime '5.70';
use parent 'Catalyst';

__PACKAGE__->config({
    Controller::CGIHandler => {
        cgi_file_pattern => ['*.sh', qr/\.pl\z/]
    },
});

__PACKAGE__->setup(qw/Static::Simple/);

1;
