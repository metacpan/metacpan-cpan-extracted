# Defines some Perl functions for the *.t scripts
use strict;
use warnings;

sub P() {
	no strict 'refs';
	return ${(caller(1))[0].'::p'};
}

sub bbtest($$;$) {
	my($src,$bbexpect,$htmlexpect);
	if(@_ == 3) {
		($src,$bbexpect,$htmlexpect) = @_;
	} else {
		($src,$htmlexpect) = @_;
		$bbexpect = $src;
	}

	my $msg = $src;
	$msg =~ s/\t/\\t/g;
	$msg =~ s/\n/\\n/g;

	my $tree = P->parse($src);

	is($tree->toBBCode, $bbexpect, "$msg (BBCode)");

	my $html = $tree->toHTML;
	$html =~ s/&apos;/&#39;/g;
	$html =~ s#^<div class="bbcode-body">\s*##;
	$html =~ s#\s*</div>\s*$##;
	$htmlexpect =~ s/^\s+|\s+$//g;
	$htmlexpect =~ s/&apos;/&#39;/g;

	is($html, $htmlexpect, "$msg (HTML)");
}

sub bbfail($) {
	my($src) = @_;

	my $msg = $src;
	$msg =~ s/\t/\\t/g;
	$msg =~ s/\n/\\n/g;

	eval {
		P->parse($src);
	};

	isnt("$@", "", "$msg (Failure)");
}

1;
# vim:set ft=perl:
