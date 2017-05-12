use 5.008008;
use ExtUtils::MakeMaker;
package MY;
sub test_via_harness {
  my($self, $perl, $tests) = @_;
  local $_ = $self->SUPER::test_via_harness($perl, $tests);
  s/PERL_DL_NONLAZY=1//g;
  return $_;
}

sub test_via_script {
  my($self, $perl, $tests) = @_;
  local $_ = $self->SUPER::test_via_script($perl, $tests);
  s/PERL_DL_NONLAZY=1//g;
  return $_;
}

package main;

WriteMakefile(
    NAME         => 'Apache2::FakeRequest',
    VERSION_FROM => 'lib/Apache2/FakeRequest.pm',    # finds $VERSION
    PREREQ_PM    => { 'Apache2::Request' => 2.07 },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Apache2/FakeRequest.pm',    # retrieve abstract from module
            AUTHOR => 'Jeffrey H. Platter <jplatter@localdomain>'
          )
        : ()
    ),
);
