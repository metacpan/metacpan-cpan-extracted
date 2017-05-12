package Foo;
use Dancer ':syntax';

use FindBin;

our $VERSION = '0.1';

set appname => 'Foo';

set views => $FindBin::Bin.'/apps/Foo/views';

set engines => {
    mason => { 
        default_escape_flags => [ 'h' ],
        extension => 'm',
    },
};

set template => 'mason';

get '/' => sub {
    template 'index';
};

true;
