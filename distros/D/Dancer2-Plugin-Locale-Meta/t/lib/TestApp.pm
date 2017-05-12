package t::lib::TestApp;

use Dancer2;
use Cwd;

BEGIN{
  set plugins => {
      'Locale::Meta' => {
        'locale_path_directory' => Cwd->cwd.'/t/i18n'
      },
  };
}


get '/' => sub {
  return "ok";
};

1;
