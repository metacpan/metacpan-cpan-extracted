package TestApp;

use strict;
use warnings;

use FindBin;

use Catalyst;
use Excel::Template::Plus;
use Path::Class;

use TestApp::View::Excel;

__PACKAGE__->config({
    name => 'TestApp',
    'View::Excel::Template::Plus' => {
        etp_config => {
            INCLUDE_PATH => [ 
                (dir($FindBin::Bin, 'templates' )->stringify . '/'), 
            ]
        }
    }
});

__PACKAGE__->setup;

1;

__END__
