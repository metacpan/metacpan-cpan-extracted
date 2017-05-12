# -*- eval: (visual-line-mode) -*-

use strict;
use warnings;

use App::lookup;

use Test::More;
use Test::Output;

use FindBin ();
use File::Spec;
use Text::Abbrev 'abbrev';

# how do I test this kind of thing anyway?

my $CONFIG_FILE =
  File::Spec->catfile($FindBin::Bin, 'config.ini');

stdout_like {
    App::lookup::print_sites(App::lookup::initialize_sites($CONFIG_FILE));
}
qr{- google : http://google.com/search\?q=%\(query\)\n},
  "the option --print-sites prints the expected output";

stdout_like {
    App::lookup::print_sites(App::lookup::initialize_sites($CONFIG_FILE));
}
qr{- a\s+: http://www.amazon.com/s/&field-keywords=%\(query\)},
"the output of the option --print-sites contains amazon (which means the config file is read correctly)";

is_deeply App::lookup::initialize_sites($CONFIG_FILE),
  {
    google => 'http://google.com/search?q=%(query)',
    bing   => 'http://www.bing.com/search?q=%(query)',
    cpan   => 'http://search.cpan.org/search?query=%(query)&mode=all',
    a      => 'http://www.amazon.com/s/&field-keywords=%(query)',
  },
'initialize_sites returns the expected hashref (with user-defined sites and aliases)';

subtest 'print abbrevs' => sub {
    my $sites   = App::lookup::initialize_sites($CONFIG_FILE);
    my $abbrevs = abbrev keys %$sites;

    stdout_like { App::lookup::print_abbrevs($abbrevs, $sites) }
qr{Name      : a\nURL       : http://www.amazon.com/s/&field-keywords=%\(query\)\nAbbrev\(s\) : a\n\nName      : bing\nURL       : http://www.bing.com/search\?q=%\(query\)\nAbbrev\(s\) : b, bi, bin, bing},
      'print_abbrevs prints the expected output';
};

done_testing;
