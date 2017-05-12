package Template::Plugin::html2text;

use warnings;
use strict;

use Template::Plugin::Filter;
use base 'Template::Plugin::Filter';

use HTML::Parser;

my %inside;
my (@links, @notes);
my $text;

sub filter {
	my ($self, $text_in) = @_;

	my $p = HTML::Parser->new(
		api_version   => 3,
		report_tags => [qw(a img b i p pre ul li abbr table th tr td)],
		handlers	=> [
			start => [ \&tag_handler,  'self, tagname, attr, event, "+1"' ],
			end   => [ \&tag_handler,  'self, tagname, attr, event, "-1"' ],
			text  => [ \&text_handler, 'self, dtext' ],
		],
		marked_sections => 1,
	);

	undef @links;
	undef @notes;
	undef %inside;

	$text = '';
	$p->parse($text_in);

	$text .= "\n" if @links;
	my $i = 0;
	foreach (@links) {
		$text .= "[$i] $links[$i]\n";
		$i++;
	}
	$text .= "\n" if @links;

	$i = 0;
	foreach (@notes) {
		$text .= "{$i} $notes[$i]\n";
		$i++;
	}
	$text .= "\n" if @notes;

	return $text;
}

sub init {
	my ($self) = @_;
	my $name = $self->{_CONFIG}->{name} || 'html2text';
	$self->install_filter($name);
	return $self;
}

##############################################################################
sub tag_handler {
	my ($self, $tag, $attr, $event, $num) = @_;

	$inside{$tag} += $num;
	if ($tag eq 'a') {
		push(@links, $attr->{href}) if exists $attr->{href};
		$text .= "[$#links]" if $event eq 'end';
	} elsif ($tag eq 'img' and $event eq 'start') {
		push(@links, $attr->{src}) if exists $attr->{src};
		$text .= '[' . ($attr->{alt} || 'IMG') . ']';
		$text .= "[$#links]";
	} elsif ($tag eq 'abbr') {
		push(@notes, $attr->{title}) if exists $attr->{title};
		$text .= "{$#notes}" if $event eq 'end';
	} elsif ($tag eq 'b') {
		$text .= '*';
	} elsif ($tag eq 'i') {
		$text .= '/';
	} elsif ($tag eq 'p' or $tag eq 'pre') {
		$text .= "\n\n" if $event eq 'end';
	} elsif ($tag eq 'table') {
		$text .= "\n" if $event eq 'end';
	} elsif ($tag eq 'tr' or $tag eq 'th') {
		$text .= "\n" if $event eq 'end';
	} elsif ($tag eq 'td') {
		$text .= "\t" if $event eq 'end';
	} elsif ($tag eq 'ul') {
	} elsif ($tag eq 'li') {
		$text .= "\n * " if $event eq 'start';
	} else {
		$text .= "{$tag:$num} [$event]";
	}
}

sub text_handler {
	my ($self, $s) = @_;

	return if $inside{script} or $inside{style};

	$s =~ s/^\n+//g;
	$s =~ s/\s+/ /g if not $inside{pre};
	$s =~ s/^\s+$//;
	$text .= $s;
}

1;
