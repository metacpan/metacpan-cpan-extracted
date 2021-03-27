package CSS::Tidy;
use warnings;
use strict;
use Carp;
use utf8;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    copy_css
    tidy_css
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

our $VERSION = '0.03';

use C::Tokenize '$comment_re';
use File::Slurper qw!read_text write_text!;

sub copy_css
{
    my (%options) = @_;
    my $in = get_option (\%options, 'in');
    if (! $in) {
	carp "Specify the input css file with in => 'file'";
	return;
    }
    my $out = get_option (\%options, 'out');
    if (! $out) {
	carp "Specify the output css file with out => 'file'";
	return;
    }
    my $css = read_text ($in);
    $css = tidy_css ($css, %options);
    write_text ($out, $css);
}

sub get_option
{
    my ($o, $name) = @_;
    my $value = $o->{$name};
    delete $o->{$name};
    return $value;
}

sub check_options
{
    my ($o) = @_;
    my @k = keys %$o;
    for my $k (@k) {
	carp "Unknown option $k";
	delete $o->{$k};
    }
}

sub tidy_css
{
    my ($text, %options) = @_;

    my $decomment = get_option (\%options, 'decomment');
    #my $verbose = 
    # Discard this at the moment, we have no verbose output yet.
    get_option (\%options, 'verbose');
    check_options (\%options);

    # Store for comments during processing. They are then restored.
    my $comments;
    if ($decomment) {
	$text = rm_comments ($text);
    }
    else {
	($text, $comments) = strip_comments ($text);
    }
    $text =~ s!(\{|\}|;)(\s*\S)!$1\n$2!g;
    $text =~ s!(\S\s*)(\})!$1\n$2!g;
    $text =~ s!(\S)(\{)!$1 $2!g;

    my @lines = split /\n/, $text;

    my @tidy;

    # Line number, but this could be wrong due to comment removal.
    my $i;

    # Depth of nested { }
    my $depth = 0;

    for (@lines) {
	$i++;
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

    $out =~ s/^\}\n(\S)/\}\n\n$1/gsm;
    # Remove a blank line before }. This also tidies up the
    # aftereffects of the above regex, which puts too many blank
    # lines.
    $out =~ s/\n\n(\s*\})/\n$1/g;

    # Add a semicolon after the final CSS instruction if there is not
    # one.

    $out =~ s!([^\};])\s*(\n\s*\})!$1;$2!g;

    if (! $decomment) {
	$out = restore_comments ($out, $comments);
    }
    # Add a blank line after comments.
    $out =~ s!(\*/)!$1\n!g;
    return $out;
}

# Completely remove all the comments.

sub rm_comments
{
    my ($text) = @_;
    $text =~ s!$comment_re!!sm;
    return $text;
}

my $string_re = qr!"(\\"|[^"])*"!;

# Strip the comments out in such a way that they can be restored.

sub strip_comments
{
    my ($text) = @_;

    # Remove and store all strings so that "http://example.com"
    # doesn't get turned into a comment.

    my @strings;
    my $s = 0;
    while ($text =~ s!($string_re)!\@\@ string_#$s \@\@!sm) {
	$s++;
	push @strings, $1;
    }

    # Remove and store comments.

    my @comments;
    my $n = 0;
    while ($text =~ s!($comment_re)!/\@ css_tidy_#$n \@/!sm) {
	$n++;
	push @comments, $1;
    }

    # Restore the strings.

    $text =~ s!\@\@ string_#([0-9]+) \@\@!$strings[$1]!g;

    return ($text, \@comments);
}

sub restore_comments
{
    my ($text, $comments) = @_;
    $text =~ s!/\@ css_tidy_#([0-9]+) \@/!$comments->[$1]!g;
    return $text;
}

1;
