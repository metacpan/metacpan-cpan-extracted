package t::lib::TestApp3;

use Dancer2;
BEGIN{
  set plugins => {
      'Locale::Meta' => {
        'locale_path_directory' => Cwd->cwd.'/t/i18n'
      },
  };
}
use Dancer2::Plugin::Locale::Meta;

hook 'before' => sub {
  my $structure = {
    "en" => {
      "goodbye"   => {
        "trans" => "bye",
      }
    },
    "es" => {
      "goodbye"   => {
        "trans" => "chao",
      }
    }
  };
  load_structure($structure);
};

get '/:lang' => sub {
  session 'lang' => param('lang');
  my $a = loc('goodbye');
  return $a;
};

1;
