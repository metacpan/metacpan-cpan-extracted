package inc::MakeMaker;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
 
use namespace::autoclean;
 
override _build_WriteMakefile_dump => sub {
  my ($self) = @_;
 
  my $str = super;
 
  $str .= ";\n\n";
 
  $str .= <<'END_NONSENSE';
$WriteMakefileArgs{PREREQ_PM} ||= {};

eval {
  local @INC = ('lib', @INC);
  require Data::GUID::Any;
  Data::GUID::Any::v1_guid_as_string(); # dies if no provider
  Data::GUID::Any::v4_guid_as_string(); # dies if no provider
  1;
} or do {
  require ExtUtils::CBuilder;
  if ( ExtUtils::CBuilder->new->have_compiler ) {
    $WriteMakefileArgs{PREREQ_PM}{'Data::UUID::MT'} = '0';
  }
  else {
    $WriteMakefileArgs{PREREQ_PM}{'UUID::Tiny'} = '0';
  }
};

# Hey, CPAN Testers, go ahead and test with extra prereqs
# that don't have external library dependencies
if ( $ENV{AUTOMATED_TESTING} ) {
  require ExtUtils::CBuilder;
  $WriteMakefileArgs{BUILD_REQUIRES}{'Data::UUID::MT'} = '0'
    if ExtUtils::CBuilder->new->have_compiler;
  $WriteMakefileArgs{BUILD_REQUIRES}{'UUID::Tiny'} = '0';
}
 
END_NONSENSE
 
  return $str;
};
 
1;
