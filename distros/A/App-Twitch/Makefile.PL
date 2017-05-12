
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Your personal Twitter b...... lalalala',
  'AUTHOR' => 'Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Twitch',
  'EXE_FILES' => [
    'bin/twitch'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Twitch',
  'PREREQ_PM' => {
    'DateTime' => '0.66',
    'Encode' => '2.42',
    'Encode::Detect' => '1.01',
    'HTML::ExtractContent' => '0.10',
    'IO::All' => '0.41',
    'JSON' => '2.5',
    'Moose' => '1.15',
    'MooseX::Daemonize' => '0.12',
    'MooseX::Getopt' => '0.33',
    'MooseX::LogDispatch' => '1.2002',
    'MooseX::POE' => '0.208',
    'MooseX::SimpleConfig' => '0.09',
    'Net::Twitter' => '3.14',
    'POE' => '1.294',
    'POE::Component::Client::HTTP' => '0.895',
    'POE::Component::Client::Keepalive' => '0.263',
    'POE::Component::FeedAggregator' => '0.902',
    'POE::Component::WWW::Shorten' => '1.20',
    'String::Truncate' => '1.100570',
    'Text::Keywords' => '0.004',
    'Text::Trim' => '1.02',
    'Text::Tweet' => '0.004',
    'URI' => '1.56',
    'WWW::Shorten' => '3.02',
    'WWW::Shorten::Bitly' => '1.14',
    'YAML::LibYAML' => '0.34'
  },
  'VERSION' => '0.904',
  'test' => {
    'TESTS' => 't/*.t'
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

WriteMakefile(%WriteMakefileArgs);



