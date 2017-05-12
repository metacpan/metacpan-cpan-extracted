# use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::View::SVG::TT::Graph',
    VERSION_FROM      => 'lib/Catalyst/View/SVG/TT/Graph.pm', # finds $VERSION
    PREREQ_PM         => {
                            'Catalyst::Action::RenderView' => '0.01',
                            'Catalyst::Runtime' => '5.80001',
                            'Catalyst::Plugin::ConfigLoader'    => '0.23',
                            'Catalyst::Plugin::Static::Simple'  => '0.01',
                            'FindBin'           => '1.42',
                            'Image::LibRSVG'    => '0.07',
                            'MIME::Types'       => '1.30',
                            'Moose'             => '1.09',
                            'SVG::TT::Graph'    => '0.21',
                            'Test::More'        => '0.94',
                            'Test::WWW::Mechanize::Catalyst' => '0.52',
                            'namespace::autoclean'  => '0.09'
                        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/View/SVG/TT/Graph.pm', # retrieve abstract from module
       AUTHOR         => 'Terence Monteiro <terencemo@cpan.org>') : ()),
       LICENSE        => 'perl'
);
