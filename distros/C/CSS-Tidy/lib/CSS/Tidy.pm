package CSS::Tidy;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/tidy_css/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.01';

sub tidy_css
{
    my ($text) = @_;

    my $depth = 0;
    my $comment = 0;

    ($text, my $comments) = strip_comments ($text);

    my @lines = split /\n/, $text;

    my @tidy;

    my $i;

    for (@lines) {
	$i++;
	if (m!^\s*/\*!) {
	    if (! m!/\*.*?\*/!) {
		$comment = 1;
		push @tidy, $_;
		next;
	    }
	}
	if ($comment) {
	    if (m!.*?\*/!) {
		$comment = 0;
		push @tidy, $_;
		next;
	    }
	}
	# {} on the same line.

	# It would be better to deal with these beforehand.

	# If done before processing it will break the line numbers.

	# Need to also add then remove line number fake information.

	if (/^\s*(.*)\{(.*?)\}(.*)$/) {
	    my ($before, $between, $after) = ($1, $2, $3);
	    my $indent = '    ' x ($depth + 1);
	    push @tidy, "$indent$before {";
	    my @between = split /;\s*/, $between;
	    for my $b (@between) {
		push @tidy, "$indent    $b";
	    }
	    push @tidy, "$indent}";
	    push @tidy, "$indent$after";
	    next;
	}
	if (/\}/) {
	    $depth--;
	    if ($depth < 0) {
		warn "$i: depth = $depth\n";
	    }
	}
	my $initial = '';
	if (/^(\s*)/) {
	    $initial = $1;
	}
	if (length ($initial) != $depth * 4) {
	    s/^$initial/'    ' x $depth/e;
	}
	# If not a CSS pseudoclass or pseudoelement
	if (! /(?:\.|#)\w+.*?:/ && ! /^\s*:+/) {
	    # Insert a space after a colon
	    s/([^:]):(\S)/$1: $2/;
	}
	s/\s+$//;
	push @tidy, $_;
	if (/\{/) {
	    $depth++;
	}
    }

    my $out = join ("\n", @tidy);
    # Reduce multiple blank lines to a single one.
    $out =~ s/\n+/\n/g;
    # Add a blank after }
    $out =~ s/^(\s*\})/$1\n/gsm;
    # Remove a blank line before }. This also tidies up the
    # aftereffects of the above regex, which puts too many blank
    # lines.
    $out =~ s/\n\n(\s*\})/\n$1/g;
    $out = restore_comments ($out, $comments);
    # Add a blank line after comments.
    $out =~ s!(\*/)!$1\n!g;
    return $out;
}

my $trad_comment_re = qr!
    /\*
    (?:
	# Match "not an asterisk"
	[^*]
    |
	# Match multiple asterisks followed
	# by anything except an asterisk or a
	# slash.
	\*+[^*/]
    )*
    # Match multiple asterisks followed by a
    # slash.
    \*+/
!x;

sub strip_comments
{
    my ($text) = @_;
    my @comments;
    my $n = 0;
    while ($text =~ s!($trad_comment_re)!// css_tidy_#$n //!sm) {
	$n++;
	push @comments, $1;
    }
    return ($text, \@comments);
}

sub restore_comments
{
    my ($text, $comments) = @_;
    $text =~ s!// css_tidy_#([0-9]+) //!$comments->[$1]!g;
    return $text;
}

1;
