package t::lib::TestApp4;

use Dancer2;
BEGIN{
  set plugins => {
      'Locale::Meta' => {
        'locale_path_directory' => Cwd->cwd.'/t/i18n',
        'fallback' => "en"
      },
  };
}
use Dancer2::Plugin::Locale::Meta;

hook 'before' => sub {
  my $structure = {
    "en" => {
      "goodbye"   => {
        "trans" => "bye",
      },
      "only_english" => {
        "trans" => "in english"
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
  my $a = loc('only_english');
  return $a;
};


1;
