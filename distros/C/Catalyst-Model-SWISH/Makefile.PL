use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Catalyst::Model::SWISH',
    VERSION_FROM      => 'lib/Catalyst/Model/SWISH.pm', # finds $VERSION
    PREREQ_PM         => {
   
        'Catalyst::Runtime'     => 5.7, 
        'SWISH::API::Object'    => 0.09,
        'MRO::Compat'           => 0,
        'Time::HiRes'           => 1.86,
        'Data::Pageset'         => 1.03,
        'Sort::SQL'             => 0.03,
        
        # for tests
        'Catalyst::Action::RenderView' => 0,
        'Catalyst::View::TT' => 0,
        'Template::Plugin::Handy' => 0,
        'Catalyst::Plugin::ConfigLoader' => 0,
        'Catalyst::Plugin::Static::Simple' => 0,
        
        

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Model/SWISH.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Karman <perl@peknet.com>') : ()),
);
