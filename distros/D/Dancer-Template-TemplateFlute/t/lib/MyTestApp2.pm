package MyTestApp2;

use Dancer ':syntax';

set engines => { template_flute => { i18n => { class => 'MyTestApp::Lexicon' } } };

get '/en' => sub {
    var lang => 'en';
    template 'i18n';
};

get '/it' => sub {
    var lang => 'it';
    template 'i18n';
};

true;
