package MyApp;
use Catalyst;

MyApp->config(
  'View::Summary' => {
    copydate => 2017,  
  }
);

MyApp->setup;
