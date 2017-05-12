use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Algorithm::SkipList',
     license => 'perl',
     requires => {
       'base'                       => 0,
       'enum'                       => 1.016,
       'perl'                       => '5.6.1',
     },
     recommends => {
     },
     build_requires => {
       'Test::More'                 => 0,
       'Test::Warn'                 => 0,
     },
     autosplit => 'lib/Algorithm/SkipList.pm',
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign               => 1,
);

$build->create_build_script;
