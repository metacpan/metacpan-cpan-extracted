use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;


my $meta_merge = {
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  =>  {
                type => 'git',
                url => 'git@github.com:Virendrabaskar/Catalyst-View-XLSX.git',
                web => 'https://github.com/Virendrabaskar/Catalyst-View-XLSX'
            },
        },
    }
};

my %WriteMakefileArgs = (
  "ABSTRACT" => "Catalyst View for Microsoft Excel (XLSX) file",
  "AUTHOR" => "Baskar Nallathambi <baskarmusiri\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::View" => 0,
    "Excel::Writer::XLSX" => 0,
    "File::Spec" => 0,                                                        
    "File::Temp" => 0,                                                        
    "URI::Escape" => 0,
    "FindBin" => 0,
    "Moose" => 0,
    "Test::More" => 0,
    "Catalyst::Test" => 0,
    "Catalyst::Action::RenderView" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-View-XLSX",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::View::XLSX",
  "PREREQ_PM" => {
    "Catalyst::View" => 0,
    "Catalyst::Action::RenderView" => 0,
    "Excel::Writer::XLSX" => 0,
    "File::Spec" => 0,                                                        
    "File::Temp" => 0,                                                        
    "URI::Escape" => 0  
  },
  "VERSION" => "1.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

  WriteMakefile(%WriteMakefileArgs,
      $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : ());




