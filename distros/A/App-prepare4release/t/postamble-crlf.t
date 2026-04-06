#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(like unlike);

use App::prepare4release;

# CRLF: the marked PREPARE4RELEASE block must be replaceable (pod2github vs pod2markdown).
{
	my $crlf =
		  "# BEGIN PREPARE4RELEASE_POSTAMBLE\r\n"
		. "sub MY::postamble { return ''; }\r\n"
		. "# END PREPARE4RELEASE_POSTAMBLE\r\n";

	my $new = App::prepare4release->ensure_postamble(
		$crlf,
		{ github => 1, gitlab => 0, cpan => 0 },
		0
	);
	like( $new, qr/pod2github\b/, 'CRLF: PREPARE4RELEASE block replaced (pod2github)' );
	unlike( $new, qr/pod2markdown\b/, 'CRLF: not left on pod2markdown' );
}

# Unix LF: delimiter lines are literally "# BEGIN ..." / "# END ..." (spaces after #).
# Regression guard: a regex must not use /x in a way that strips those spaces, or the
# block is never replaced and Makefile.PL stays on pod2markdown with --github.
{
	my $lf =
		  "# BEGIN PREPARE4RELEASE_POSTAMBLE\n"
		. "sub MY::postamble { return ''; }\n"
		. "# END PREPARE4RELEASE_POSTAMBLE\n";

	my $new = App::prepare4release->ensure_postamble(
		$lf,
		{ github => 1, gitlab => 0, cpan => 0 },
		0
	);
	like( $new, qr/pod2github\b/, 'LF: PREPARE4RELEASE block replaced (pod2github)' );
	unlike( $new, qr/pod2markdown\b/, 'LF: not left on pod2markdown' );
}

# Realistic fragment: pod2markdown in heredoc must become pod2github when --github.
{
	my $lf = <<'MAKEFILE';
# BEGIN PREPARE4RELEASE_POSTAMBLE
sub MY::postamble {
  return '' if !-e '.git';
  <<'PREPARE4RELEASE_POD2README';
pure_all :: README.md

README.md : $(VERSION_FROM)
	pod2markdown $< $@
	$(PERL) maint/inject-readme-badges.pl
PREPARE4RELEASE_POD2README
}
# END PREPARE4RELEASE_POSTAMBLE
MAKEFILE

	chomp $lf;
	$lf .= "\n";

	my $new = App::prepare4release->ensure_postamble(
		$lf,
		{ github => 1, gitlab => 0, cpan => 0 },
		0
	);
	like( $new, qr/\bpod2github\b/, 'realistic LF block: pod2github' );
	unlike( $new, qr/\bpod2markdown\b/, 'realistic LF block: no pod2markdown' );
	like( $new, qr/inject-readme-badges\.pl/, 'realistic LF block: badge injector kept' );
}

done_testing;
