package t::lib::TestApp1;

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
  my $a = loc('greeting');
  return $a;
};

1;
