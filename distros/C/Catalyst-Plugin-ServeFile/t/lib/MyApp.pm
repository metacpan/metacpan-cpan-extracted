package MyApp;

use Catalyst 'ServeFile';

MyApp->config('Plugin::ServeFile' => {show_log=>1});
MyApp->setup;
