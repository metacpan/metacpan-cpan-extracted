
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "an advanced way to manage/track/serve thoughts/articles/posts",
  "AUTHOR" => "sunnavy <sunnavy\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Memory::Cycle" => 0,
    "Test::More" => 0,
    "Test::Script::Run" => 0,
    "Test::WWW::Mechanize" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Beagle",
  "EXE_FILES" => [
    "bin/beagle"
  ],
  "LICENSE" => "perl",
  "NAME" => "Beagle",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "Class::Load" => 0,
    "Config::INI::Reader" => 0,
    "Config::INI::Writer" => 0,
    "Data::Page" => 0,
    "Data::UUID" => 0,
    "DateTime" => 0,
    "DateTime::Format::Mail" => 0,
    "DateTimeX::Easy" => 0,
    "Devel::Size" => 0,
    "Email::Address" => 0,
    "Encode::Locale" => 0,
    "File::Copy::Recursive" => 0,
    "File::HomeDir" => 0,
    "File::ShareDir::Install" => 0,
    "File::Slurp" => 0,
    "File::Which" => 0,
    "HTML::Defang" => 0,
    "HTML::Entities" => 0,
    "IO::Page" => 0,
    "IPC::Run3" => 0,
    "JSON" => 0,
    "Lingua::EN::Inflect" => 0,
    "List::MoreUtils" => 0,
    "Locale::Maketext::Lexicon" => 0,
    "MIME::Entity" => 0,
    "MIME::Types" => 0,
    "Module::Pluggable::Object" => 0,
    "Module::Refresh" => 0,
    "Mouse" => "0.89",
    "MouseX::App::Cmd" => 0,
    "Number::Format" => 0,
    "Plack" => 0,
    "Plack::Middleware::Static" => 0,
    "Pod::Simple" => 0,
    "Proc::InvokeEditor" => 0,
    "Router::Simple" => 0,
    "Term::ReadKey" => 0,
    "Term::ReadLine::Perl" => 0,
    "Term::Size" => 0,
    "Text::MultiMarkdown" => 0,
    "Text::Table" => 0,
    "Text::WikiFormat" => 0,
    "Text::Xslate" => 0,
    "URI::QueryParam" => 0,
    "XML::FeedPP" => 0
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t t/api/*.t t/cli/*.t t/web/*.t"
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

if ( $^O eq 'MSWin32' ) {
  $WriteMakefileArgs{PREREQ_PM}{'Term::Size::Win32'} = '0';
}

WriteMakefile(%WriteMakefileArgs);

package
MY;
use File::ShareDir::Install qw(postamble);


