use ExtUtils::MakeMaker;

my $readme = 'podselect $(VERSION_FROM) > README.pod';

WriteMakefile 
(

  NAME          => "Catalyst::Controller::FormBuilder::MultiForm",
  AUTHOR        => "Danny Warren <danny\@dannywarren.com>",
  LICENSE       => "perl",
  VERSION_FROM  => "lib/Catalyst/Controller/FormBuilder/MultiForm.pm",
  ABSTRACT_FROM => "lib/Catalyst/Controller/FormBuilder/MultiForm.pm",

  PREREQ_PM =>
  {
    'Catalyst::Controller::FormBuilder' => "0.06",
    'Catalyst::Runtime'                 => "5.7",
  },

  TEST_REQUIRES => 
  {
    'Test::Simple'                   => "0.44",
    'Test::WWW::Mechanize::Catalyst' => "0.37",
    'Class::Inspector'               => "1.16",
    'Catalyst::View::TT'             => "0.44",
  },

  META_MERGE =>
  {
    recommends =>
    {
      'Catalyst::View::TT' => "0.44",
      'HTML::Template'     => "2.95",
      'Mason'              => "2.24",
    },
    resources => 
    {
      homepage   => "https://github.com/dannywarren/Catalyst-Controller-FormBuilder-MultiForm",
      repository => "https://github.com/dannywarren/Catalyst-Controller-FormBuilder-MultiForm",
    },
  },

  dist => 
  {
    PREOP => $readme,
  }

);
