
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Copy secrets from a YAML/JSON cipherstore into the clipboard (pbcopy, xsel, xclip)',
  'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-locket',
  'EXE_FILES' => [
    'bin/locket',
    'bin/locket'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::locket',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'Crypt::Random' => '0',
    'Crypt::Rijndael' => '0',
    'Digest::SHA' => '0',
    'File::HomeDir' => '0',
    'Getopt::Usaginator' => '0',
    'Hash::Dispatch' => '0',
    'JSON' => '0',
    'MIME::Base64' => '0',
    'Path::Class' => '0',
    'String::Util' => '0',
    'Term::EditorEdit' => '0',
    'Term::ReadKey' => '0',
    'Try::Tiny' => '0',
    'YAML::XS' => '0'
  },
  'VERSION' => '0.0022',
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



