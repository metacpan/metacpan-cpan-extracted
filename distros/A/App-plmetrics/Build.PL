use strict;
use warnings;
use Module::Build;

my %SUGGESTS = (
    'File::Temp' => 0,
    'Path::Class' => 0,
    'Git::Repository' => 0,
    'LWP::Simple' => 0,
    'Archive::Tar' => 0,
);
my %REQUIRES = ();

if ($ENV{AUTHOR_TEST} || $ENV{CI} || $ENV{TRAVIS}) {
    %REQUIRES = %SUGGESTS;
    %SUGGESTS = ();
}

my $builder = Module::Build->new(
    module_name         => 'App::plmetrics',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/plmetrics.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Capture::Tiny' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'strict' => 0,
        'warnings' => 0,
        'Docopt' => 0,
        'Module::Path' => 0,
        'Perl::Metrics::Lite' => 0,
        'Text::ASCIITable' => 0,
        'Statistics::Swoop' => 0,
        %REQUIRES,
    },
    suggests => {
        %SUGGESTS,
    },
    script_files        => [ 'script/plmetrics' ],
    add_to_cleanup      => [ 'App-plmetrics-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-plmetrics'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
