use Test2::V0 -no_srand => 1;
use Clang::CastXML::Find;
use Path::Tiny qw( path );
use Env qw( @PATH );
use 5.022;

BEGIN { $ENV{DEVEL_HIDE_VERBOSE} = 0 }

my $orig = $ENV{PATH};

delete $ENV{PERL_CLANG_CASTXML_PATH};
@PATH = ();

subtest 'env var' => sub {

  use Devel::Hide qw( -lexically Alien::castxml );

  local $ENV{PERL_CLANG_CASTXML_PATH} = path('corpus/bin/castxml')->absolute->stringify;

  my $exe = Clang::CastXML::Find->where;
  ok -e $exe, 'found castxml executable';

};

subtest 'path' => sub {

  use Devel::Hide qw( -lexically Alien::castxml );

  local $ENV{PATH} = $ENV{PATH};
  @PATH = path('corpus/bin')->absolute->stringify;

  my $exe = Clang::CastXML::Find->where;
  ok -e $exe, 'found castxml executable';

};

subtest 'fail' => sub {

  use Devel::Hide qw( -lexically Alien::castxml );

  is(
    dies { Clang::CastXML::Find->where },
    match qr/Unable to find castxml/,
    'no found castxml executable'
  );

};

subtest 'alien' => sub {

  skip_all 'subtest requires Alien::castxml'
    unless eval { require Alien::castxml; 1 };

  local $ENV{PATH} = $orig;

  my $exe = Clang::CastXML::Find->where;
  ok -e $exe, 'found castxml executable';

};

done_testing;
