# mamgal - a program for creating static image galleries
# Copyright 2007-2011 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# An output formatting class, for creating the actual index files from some
# contents
package App::MaMGal::Formatter;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;
use Locale::gettext;
use URI::file;
use HTML::Entities qw(encode_entities_numeric);
use App::MaMGal::Logger;

sub init
{
	my $self = shift;
	my $le = shift or croak "Need a locale env arg";
	ref $le and $le->isa('App::MaMGal::LocaleEnv') or croak "Arg is not a App::MaMGal::LocaleEnv, but a [$le]";
	$self->set_locale_env($le);
}

sub set_locale_env
{
	my $self = shift;
	my $le = shift;
	$self->{locale_env} = $le;
}

sub HEADER
{
	my $self = shift;
	my $head = shift || '';
	sprintf("<html><head><meta http-equiv='Content-Type' content='text/html; charset=%s'>%s</head><body>", $self->{locale_env}->get_charset, $head);
}

sub MAYBE_LINK
{
	my $self = shift;
	my $link = shift;
	my $text = shift;
	if ($link) {
		$self->LINK($link.'.html', $text)
	} else {
		$text
	}
}

sub MAYBE_IMG
{
	my $self = shift;
	my $img = shift;
	if ($img) {
		sprintf("<img src='%s'/>", encode_entities_numeric(URI::file->new($img)->as_string));
	} else {
		# TRANSLATORS: This text will appear literally where no thumbnail is avaialable
		# for a given object.
		# Please use &nbsp; for whitespace, to avoid line breaks.
		gettext('[no&nbsp;icon]');
	}
}

sub MAYBE_EMBED
{
	my $self = shift;
	my $film = shift;
	if ($film) {
		sprintf("<embed src='%s'/>", encode_entities_numeric(URI::file->new($film)->as_string));
	} else {
		# TRANSLATORS: This text will appear literally where no path is
		# avaialable for a given film.
		# Please use &nbsp; for whitespace, to avoid line breaks.
		gettext('[no&nbsp;film]');
	}
}

sub LINK
{
	my $self = shift;
	my $link = encode_entities_numeric(URI::file->new(shift)->as_string);
	my $text = shift;
	"<a href='$link'>$text</a>";
}

# TRANSLATORS: The following three are for navigation on a slide page (&lt; is shown as <, and &gt; as >)
sub PREV                { gettext('&lt;&lt; prev') }
sub NEXT                { gettext('next &gt;&gt;') }
sub LINK_DOWN		{ $_[0]->LINK('../index.html', gettext('Up a dir')) }
sub FOOTER		{ "</body></html>"; }
sub EMPTY_PAGE_TEXT	{ gettext("This directory is empty") }
sub CURDIR		{ sprintf '<span class="curdir">%s</span>', $_[1] }

sub format
{
	my $self = shift;
	my $dir  = shift;
	croak "Only one arg is required" if @_;
	my @elements = $dir->elements;
	my @containers = $dir->containers;
	my $down_dots = join('/', map { ".." } @containers);
	$down_dots .= '/' if $down_dots;
	my $ret = $self->HEADER('<link rel="stylesheet" href="'.$down_dots.'.mamgal-style.css" type="text/css">')."\n";
	$ret .= '<table class="index">';
	$ret .= '<tr><th colspan="4" class="header_cell">';
	$ret .= join(' / ', map { $self->CURDIR($_->name) } @containers, $dir);
	$ret .= '</th></tr>'."\n";
	$ret .= ($dir->is_root ? '' : '<tr><th colspan="4" class="header_cell">'.$self->LINK_DOWN.'</th></tr>')."\n";
	$ret .= "\n<tr>\n";
	my $i = 1;
	if (@elements) {
		my $previous_description = undef;
		foreach my $e (@elements) {
			confess "[$e] is not an object" unless ref $e;
			confess "[$e] is a ".ref($e) unless $e->isa('App::MaMGal::Entry');
			my $this_description = $e->description;
			$ret .= '  '.$self->entry_cell($e, ($this_description and $previous_description and ($this_description eq $previous_description)))."\n";
			$ret .= "</tr>\n<tr>\n" if $i % 4 == 0;
			$i++;
			$previous_description = $this_description;
		}
	} else {
		$ret .= '<td colspan="4">'.$self->EMPTY_PAGE_TEXT.'</td>';
	}
	$ret .= "</tr>\n";
	return $ret.$self->FOOTER;
}

sub entry_cell
{
	my $self  = shift;
	my $entry = shift;
	my $suppress_description = shift;
	my $path = $entry->page_path;
	my $thumbnail_path = $entry->thumbnail_path;
	my $ret = '';
	$ret .= '<td class="entry_cell">';
	my @timeret;
	foreach my $time ($entry->creation_time()) {
		push @timeret, sprintf('<span class="date">%s</span> <span class="time">%s</span>', $self->{locale_env}->format_date($time), $self->{locale_env}->format_time($time));
	}
	$ret .= '<br>'.join(' &mdash; ', @timeret).'<br>';
	$ret .= $self->LINK($path, $self->MAYBE_IMG($thumbnail_path));
	if ($entry->description and not $suppress_description) {
		$ret .= sprintf('<br><span class="desc">%s</span>', $entry->description);
	} else {
		$ret .= sprintf('<br><span class="filename">[%s]</span><br>', $self->LINK($path, $entry->name));
	}
	$ret .= '</td>';
	return $ret;
}

sub format_slide
{
	my $self = shift;
	my $pic  = shift or croak "No pic";
	croak "Only one arg required." if @_;
	ref $pic and $pic->isa('App::MaMGal::Entry::Picture') or croak "Arg is not a pic";

	my ($prev, $next) = map { defined $_ ? $_->name : '' } $pic->neighbours;

	my @containers = $pic->containers;
	my $down_dots = join('/', map { ".." } @containers);
	my $r = $self->HEADER('<link rel="stylesheet" href="'.$down_dots.'/.mamgal-style.css" type="text/css">')."\n";
	$r .= '<div style="float:left">';
	$r .= $self->MAYBE_LINK($prev, $self->PREV);
	$r .= ' | ';
	# TRANSLATORS: This is the text of the link from a slide page to the index page.
	$r .= $self->LINK('../index.html', gettext('index'));
	$r .= ' | ';
	$r .= $self->MAYBE_LINK($next, $self->NEXT);
	$r .= '</div>';

	$r .= '<div style="float:right">[ ';
	$r .= join(' / ', map { $self->CURDIR($_->name) } @containers);
	$r .= " ]</div><br>\n";

	$r .= "<p>\n";
	if ($pic->description) {
		$r .= sprintf('<span class="slide_desc">%s</span>', $pic->description);
	} else {
		$r .= sprintf('[<span class="slide_filename">%s</span>]', $pic->name);
	}
	$r .= "</p>\n";

	if ($pic->isa('App::MaMGal::Entry::Picture::Film')) {
		$r .= $self->MAYBE_EMBED('../'.$pic->name);
		$r .= '<br>';
		$r .= $self->LINK('../'.$pic->name, gettext('Download'));
	} else {
		$r .= $self->LINK('../'.$pic->name, $self->MAYBE_IMG('../'.$pic->medium_dir.'/'.$pic->name));
	}
	my $time = $pic->creation_time();
	$r .= sprintf('<br><span class="date">%s</span> <span class="time">%s</span><br>', $self->{locale_env}->format_date($time), $self->{locale_env}->format_time($time));
	$r .= $self->FOOTER;
	return $r;
}

sub stylesheet
{
	my $t = <<END;
table.index { width: 100% }
.entry_cell { text-align: center }
.slide_desc     { font-weight: bold }
.slide_filename { font-family: monospace }
.filename { font-family: monospace }
.curdir { font-size: xx-large; font-weight: normal }
.date { font-size: small }
.time { font-size: small }
END
	return $t;
}

1;
