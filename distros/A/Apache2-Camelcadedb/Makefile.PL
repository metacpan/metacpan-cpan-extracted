#!perl

use 5.008;

use ModPerl::MM ();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %test_requires = (
    'Test::More'                => 0,
    'JSON::XS'                  => 0,
);

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# provide the test harness
Apache::TestRunPerl->generate_script();

ModPerl::MM::WriteMakefile(
    NAME          => 'Apache2::Camelcadedb',
    AUTHOR        => 'Mattia Barbon <mbarbon@cpan.org>',
    VERSION_FROM  => 'lib/Apache2/Camelcadedb.pm',
    ABSTRACT_FROM => 'lib/Apache2/Camelcadedb.pm',
    PREREQ_PM => {
        'mod_perl2'          => 0,
        'Devel::Camelcadedb' => 0,
        $mm_ver < 6.5503 ? %test_requires : (),
    },
    ( $mm_ver >= 6.48 ?     ( MIN_PERL_VERSION  => 5.008 ) :
                            () ),
    ( $mm_ver >= 6.64 ?     ( TEST_REQUIRES     => \%test_requires ) :
      $mm_ver >= 6.5503 ?   ( BUILD_REQUIRES    => \%test_requires ) :
                            () ),
    ( $mm_ver >= 6.31 ?     ( LICENSE           => 'perl' ) :
                            () ),
    ( $mm_ver >= 6.46 ?
      ( META_MERGE  => {
          "meta-spec" => { version => 2 },
          resources   => {
              bugtracker  => {
                  web    => 'https://github.com/mbarbon/apache2-camelcadedb/issues',
              },
              repository  => {
                  url  => 'git@github.com:mbarbon/apache2-camelcadedb.git',
                  web  => 'https://github.com/mbarbon/apache2-camelcadedb',
                  type => 'git',
              },
          },
        },
    ) : () ),
);
