use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'CGI::Wiki::Simple',
    VERSION_FROM  => 'lib/CGI/Wiki/Simple.pm', # finds $VERSION
    AUTHOR        => 'Max Maischein (corion@cpan.org)',
    ABSTRACT_FROM => 'lib/CGI/Wiki/Simple.pm',
    PREREQ_PM     => { 'Test::More' => 0,
                       'Test::MockObject' => 0,
                       'Test::Without::Module' => 0.01,
                       'Test::HTML::Content' => 0.03,
                       'CGI::Wiki' => 0.26,
                       'Class::Delegation' => 1.06,
                       'HTML::Entities' => 0,
                       'CGI::Application' => 3.0,
                       'URI::Escape' => 0,
                       },
);

use vars qw($have_test_inline $have_class_delegation);
BEGIN {
  eval { require Test::Inline;
         $have_test_inline = $Test::Inline::VERSION ge '0.15_001'; };
  undef $@;
  if ($have_test_inline) {
    print "Good - you have a patched Test::Inline\n";
  } else {
    print "Test::Inline 0.15_001 is nice for testing the examples, but not necessary\n"
  };
};

# Autocreate the synopsis test from the pod of every module
# (if we have Test::Inline)
{
    package MY;
    use strict;
    sub top_targets {

        my($self) = @_;
        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
        return $out unless $main::have_test_inline;

        $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        $out .= "\n\ntestifypods : \n";

        foreach my $pod (keys %{$self->{MAN1PODS}},
                         keys %{$self->{MAN3PODS}})
        {
            (my $test = $pod) =~ s/\.(pm|pod)$//;
            $test =~ s|/|-|g;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "embedded-$test.t";
            $out .= "\t$self->{NOECHO}\$(POD2TEST_EXE) ".
                    "$pod t/$test\n";
        }

        return $out;
    }
}