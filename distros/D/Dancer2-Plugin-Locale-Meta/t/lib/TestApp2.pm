package t::lib::TestApp2;

use Dancer2;
BEGIN{
  set plugins => {
      'Locale::Meta' => {
        'locale_path_directory' => Cwd->cwd.'/t/i18n'
      },
  };
}
use Dancer2::Plugin::Locale::Meta;

get '/:lang' => sub {
  session 'lang' => param('lang');
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
  my $a = loc('goodbye');
  return $a;
};

1;
