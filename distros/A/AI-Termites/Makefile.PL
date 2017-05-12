use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'AI::Termites',
               VERSION_FROM => 'lib/AI/Termites.pm', # finds $VERSION
               PREREQ_PM => { 'Math::Vector::Real' => '0.06',
                              'Math::Vector::Real::Random' => '0.02',
                              'Math::nSphere' => '0.01',
                              'Math::Vector::Real::kdTree' => '0.03',
                              'Math::Vector::Real::MultiNormalMixture' => '0.01'},
               ABSTRACT_FROM => 'lib/AI/Termites.pm', # retrieve abstract from module
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>'
             );
