package MyApp;

use Catalyst;

MyApp->config('Model::Path' => {extension=>'html'});
MyApp->setup;
