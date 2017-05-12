package Foo;

use Dancer ':syntax';

use Dancer::Template::TemplateDeclare;

use FindBin;

our $VERSION = '0.1';

set appname => 'Foo';

set views => $FindBin::Bin.'/apps/Foo/views';

set engines => {
    TemplateDeclare => { 
        dispatch_to => [ 'TD' ],
    },
};

set template => 'TemplateDeclare';

get '/' => sub {
    set layout => undef;

    template 'simple';
};

get '/layout' => sub {
    set layout => 'foo';

    template 'simple';
};

get '/bad_layout' => sub {
    set layout => 'fool';

    template 'simple';
};

true;
