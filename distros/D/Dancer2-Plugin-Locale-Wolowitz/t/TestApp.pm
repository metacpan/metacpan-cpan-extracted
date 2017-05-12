package TestApp;

use Dancer2;
use Dancer2::Plugin::Locale::Wolowitz;

set template => 'template_toolkit';
set plugins  => {
    'Locale::Wolowitz' => {
        fallback => 'en',
        lang_available => [ qw( en fr ) ],
    },
};
set session => 'Simple';

get '/' => sub {
    session lang => param('lang');
    my $tr = loc('welcome');
    return $tr;
};

get '/tmpl' => sub {
    template 'index', {}, { layout => undef };;
};

get '/no_key' => sub {
    my $tr = loc('hello');
    return $tr;
};

get '/tmpl/no_key' => sub {
    template 'no_key';
};

get '/complex_key' => sub {
    my $tr = loc('path_not_found %1', [setting('appdir')]);
    return $tr;
};

get '/tmpl/complex_key' => sub {
    template 'complex_key', { appdir => setting('appdir') };
};
