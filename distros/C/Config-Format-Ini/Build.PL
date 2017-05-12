use Module::Build;
my $b= Module::Build->new(
        module_name        => 'Config::Format::Ini',
        dist_version_from  => 'lib/Config/Format/Ini.pm',
        dist_author        => 'Ioannis Tambouras <ioannis@cpan.org>',
        requires           => {  perl                => '5.008008',
                                'Attribute::Handlers'=>  0 ,
                                'Parse::RecDescent'  =>  0 ,
                                'File::Slurp'        =>  0 ,
                              },
        recommends         => { 'Test::More'         => 0,
                                'Test::Exception'    => 0,
                                'Test::Pod::Coverage'=> '1.0',
                                'Test::Pod'          => 0,
                              },
        license            => 'perl',
        #create_makefile_pl=> 'traditional',
        #create_readme     => 1,
);

$b->create_build_script;
