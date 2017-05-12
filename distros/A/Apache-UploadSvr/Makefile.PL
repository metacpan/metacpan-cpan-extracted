#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
my $upl = 'lib/Apache/UploadSvr.pm';
WriteMakefile(
	      'NAME'	=> 'Apache::UploadSvr',
	      'VERSION_FROM' => $upl,
	      'PREREQ_PM' => {
			      Apache::Stage => 0,
			      LWP => 0,
			     },
#	      test => { TESTS => "/dev/null" },
#	       dist => {
#			PREOP => "co -l README && pod2text $upl > README && ci -u README",
#		       }
);

sub MY::test {
  my($self)=@_;
  qq{test:\n\t$self->{NOECHO}echo Do not ever try to test this. It is rather like a
\t$self->{NOECHO}echo recipe, not a ready-to-use software. Sorry bout that. Details in the README.
\t$self->{NOECHO}echo --andreas
};
}

