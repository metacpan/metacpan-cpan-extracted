package MyTestApp3;

use Dancer ':syntax';

set engines => { template_flute => { i18n => {
                                              class => 'MyTestApp::Lexicon2',
                                              method => 'try_to_translate',
                                              options => {
                                                          prepend => 'X ',
                                                          append => ' Z',
                                                         }
                                             }
                                   }
               };

get '/en' => sub {
    var lang => 'en';
    template 'i18n';
};

get '/it' => sub {
    var lang => 'it';
    template 'i18n';
};

true;
