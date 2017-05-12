use strictures 1;
use Test::More;
use App::MyPerl;
use App::MyPerl::Rewrite;

my %opts = (
  global_config_dir => 't/nonexistant',
  project_config_dir => 't/root'
);

my $my_perl = App::MyPerl->new(%opts);

is_deeply(
  $my_perl->perl_options,
  [ '-Mlib::with::preamble=use strict; use warnings qw(FATAL all);,lib,t/lib',
    '-MCarp::Always', '-Mstrict', '-Mwarnings=FATAL,all' ],
  'Options ok'
);

my $rewrite = App::MyPerl::Rewrite->new(%opts);

my $sw = "use strict;\nuse warnings qw(FATAL all);\n";

is(
  $rewrite->rewritten_contents("package Foo;\n1\n"),
  "# App::MyPerl preamble\n${sw}#line 1\npackage Foo;\n1\n",
  'Module rewritten ok'
);

is(
  $rewrite->rewritten_contents("#!perl\nexit 0\n"),
  "#!perl\n# App::MyPerl script preamble\nuse Carp::Always;\n"
    ."# App::MyPerl preamble\n${sw}#line 2\nexit 0\n",
  'Script rewritten ok'
);

done_testing;
