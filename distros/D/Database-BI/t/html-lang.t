#!/usr/bin/env perl

# A page built from a language template has to tell the layout which language
# that was.
#
# The layout writes the resolved language into <html lang="...">, and the
# controller supplies it per render, beside the template it belongs to.  index()
# did not, so the home page - the first page an operator sees - served
# <html lang=""> while the tutorial served lang="en", and 35 other renders were
# the same.  A screen reader, a translation tool and anything that indexes the
# page read that attribute; an empty one says the page is in no language at all.
#
# This is a source check rather than a request per route.  The pages need data,
# query parameters and, some of them, an optional module; a new action is
# exactly the one no test has fetched yet, which is how the gap survived.  The
# rule read here is the one a reviewer applies: every $self->render(...) whose
# template is built from $platform/$language has to pass language => as well.
#
# The checker is run over probe files it writes, so a pattern that had stopped
# matching fails instead of passing by finding nothing: a render without the
# key is rejected, one with it is accepted, the same call written on one line
# counts, and a page that is not built from a language template is left alone.
#
#   prove -l t/html-lang.t

use strict;
use warnings;

use Test::Most;
use File::Find ();
use File::Spec ();
use File::Temp qw(tempdir);

# The files that render pages: a controller is the only thing that calls
# render(), and the list is discovered so that a new controller is covered
# without this file being edited.
sub _controllers {
	my @files;
	File::Find::find({
		no_chdir => 1,
		wanted   => sub {
			my $file = $File::Find::name;
			push @files, $file if -f $file && $file =~ m{\Alib/.*/Controller/.*\.pm\z};
		},
	}, 'lib');

	return sort @files;
}

# The file without its comments and POD: a render call that is commented out is
# not one, and POD may quote the controller's code in an example.
sub _source_lines {
	my ($file) = @_;

	open my $fh, '<', $file or BAIL_OUT("cannot read $file: $!");
	my @raw = <$fh>;
	close $fh;
	chomp @raw;

	my @clean;
	my $in_pod = 0;
	for my $line (@raw) {
		if ($in_pod) {
			$in_pod = 0 if $line =~ /^=cut\b/;
			push @clean, '';
			next;
		}

		if ($line =~ /^=\w/) {
			$in_pod = 1 unless $line =~ /^=cut\b/;
			push @clean, '';
			next;
		}

		$line = '' if $line =~ /^\s*#/;
		push @clean, $line;
	}

	return @clean;
}

# Every render() call in the file, with the line it starts on and its whole
# text.  The call ends where its parentheses balance, counted with quoted
# strings removed first so a message containing a bracket does not end it early.
sub _renders {
	my ($file, $lines) = @_;

	my @renders;
	my ($start, $text, $depth) = (undef, '', 0);

	for my $index (0 .. $#$lines) {
		my $line = $lines->[$index];

		if (!defined $start) {
			next unless $line =~ /\$self->render\(/;
			$start = $index;
			$text  = '';
		}

		$text .= $line . "\n";

		my $bare = $line;
		$bare =~ s/'(?:[^'\\]|\\.)*'//g;
		$bare =~ s/"(?:[^"\\]|\\.)*"//g;
		$depth += ($bare =~ tr/(//) - ($bare =~ tr/)//);

		next if $depth > 0;

		push @renders, { file => $file, line => $start + 1, text => $text };
		($start, $text, $depth) = (undef, '', 0);
	}

	return @renders;
}

# Is this render one of the pages that is built from templates/<platform>/
# <language>/, and does it hand the language to the layout?
sub _language_template {
	my ($render) = @_;

	return $render->{text} =~ /template\s*=>\s*"\$platform\/\$language\// ? 1 : 0;
}

sub _hands_over_language {
	my ($render) = @_;

	return $render->{text} =~ /\blanguage\s*=>/ ? 1 : 0;
}

# ---------------------------------------------------------------------------
# The checker, on files it writes
# ---------------------------------------------------------------------------

sub _probe_renders {
	my ($source) = @_;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'Probe.pm');
	open my $fh, '>', $file or BAIL_OUT("cannot write $file: $!");
	print {$fh} $source;
	close $fh;

	my @lines = _source_lines($file);

	return _renders($file, \@lines);
}

subtest 'the checker reads a render call' => sub {
	my $gated = "\t\$self->render(\n"
		. "\t\ttemplate => \"\$platform/\$language/home\",\n"
		. "\t\thandler  => 'tt',\n"
		. "\t\tlanguage => \$language,\n"
		. "\t);\n";
	my @ok = _probe_renders($gated);
	is(scalar @ok, 1, 'a render written over several lines is one call');
	ok(_language_template($ok[0]), 'and is a page from a language template');
	ok(_hands_over_language($ok[0]), 'which passes the language');

	my $forgotten = $gated;
	$forgotten =~ s/\t\tlanguage => \$language,\n//;
	my @missed = _probe_renders($forgotten);
	is(scalar @missed, 1, 'the same call without the language is still one call');
	ok(!_hands_over_language($missed[0]), 'and is the one this file is about');

	my @one_line = _probe_renders(
		"\t\$self->render(template => \"\$platform/\$language/home\", language => \$language);\n"
	);
	is(scalar @one_line, 1, 'a call written on one line is one call too');
	ok(_language_template($one_line[0]) && _hands_over_language($one_line[0]),
		'and its language counts');

	# A plain-text reply is not a page built from a template, and neither is a
	# render of a fixed template: both are left alone.
	my @text = _probe_renders("\t\$self->render(text => 'Could not open', status => 404);\n");
	is(scalar @text, 1, 'a text reply is a render');
	ok(!_language_template($text[0]), 'but not a page from a language template');

	# A bracket inside a message must not end the call early: this one would
	# close the render at the argument, hiding the language that follows.
	my @bracketed = _probe_renders(
		"\t\$self->render(\n"
		. "\t\ttext    => 'File too large (maximum %s MiB)',\n"
		. "\t\tstatus  => 400,\n"
		. "\t\tlanguage => \$language,\n"
		. "\t);\n"
	);
	is(scalar @bracketed, 1, 'a bracketed message does not end the call');
	ok(_hands_over_language($bracketed[0]), 'so what follows it is still read');

	my @commented = _probe_renders(
		"\t# \$self->render(\n"
		. "\t#\ttemplate => \"\$platform/\$language/home\",\n"
		. "\t# );\n"
	);
	is(scalar @commented, 0, 'a commented-out render is not a render');

	my @documented = _probe_renders(
		"=head2 index\n\n    \$self->render(template => \"\$platform/\$language/home\");\n\n=cut\n"
	);
	is(scalar @documented, 0, 'nor is one quoted in the POD');
};

# ---------------------------------------------------------------------------
# The controller
# ---------------------------------------------------------------------------

my @controllers = _controllers();
cmp_ok(scalar @controllers, '>', 0, 'the scan found the controllers')
	or BAIL_OUT('no controller was found, so this file would check nothing');

my (@renders, @pages);
for my $file (@controllers) {
	my @lines = _source_lines($file);
	my @found = _renders($file, \@lines);

	push @renders, @found;
	push @pages, grep { _language_template($_) } @found;
}

cmp_ok(scalar @renders, '>', 30, 'the scan found the render calls')
	or BAIL_OUT('almost no render call was found, so the check below proves nothing');

cmp_ok(scalar @pages, '>', 30, 'and the pages rendered from a language template')
	or BAIL_OUT('no language-templated page was found, so the check below proves nothing');

ok(scalar(grep { !_language_template($_) } @renders),
	'while some renders are not language-templated pages, which this file leaves alone');

for my $page (@pages) {
	my $where = "$page->{file} line $page->{line}";

	ok(_hands_over_language($page), "$where passes the language it renders in to the layout")
		or diag(sprintf(
			"%s renders a template from \$platform/\$language but passes no language\n"
			. "to the layout:\n"
			. "%s\n"
			. "The layout writes that value into <html lang>, so without it the page\n"
			. "declares an empty language - which a screen reader, a translation tool\n"
			. "and anything that indexes the page reads.  Add, beside the template:\n"
			. "\n"
			. "    language => \$language,\n",
			$where, $page->{text},
		));
}

done_testing();
