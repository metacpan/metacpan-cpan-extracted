package CPAN::Digger::Pod;
use 5.008008;
use Moose;

our $VERSION = '0.08';

#extends 'CPAN::Digger';
extends 'Pod::Simple::HTML';

#has 'podfile' => (is => 'rw', isa => 'Str');

use CPAN::Digger::Index;

use autodie;

$Pod::Simple::HTML::Perldoc_URL_Prefix = '/m/';

# see also the perldoc_url_prefix method.

# partially taken from Pod::Simple::HTML
sub resolve_pod_page_linkx {
	my ( $self, $it ) = @_;
	return undef unless defined $it and length $it;

	# TODO better e-mail check here
	# TODO inject javascript obfuscated e-mail address
	#if ($it =~ /^\w+\@[\w.]*$/) {
	#	return "mailto:$it";
	#}

	my $url = $self->pagepath_url_escape($it);

	$url =~ s{::$}{}s;                                            # probably never comes up anyway
	$url =~ s{::}{/}g unless $self->perldoc_url_prefix =~ m/\?/s; # sane DWIM?

	return undef unless length $url;
	print "URL: $url\n";
	return "/m/$url";
}

sub process {
	my ( $self, $infile, $outfile ) = @_;

	$infile  = CPAN::Digger::Index::_untaint_path($infile);
	$outfile = CPAN::Digger::Index::_untaint_path($outfile);
	my $html;
	$self->html_css(
		qq(<link rel="stylesheet" type="text/css" title="pod_stylesheet" href="/style.css">\n),
	);
	$self->output_string( \$html );
	$self->parse_file($infile);
	return if not $html;

	open my $out, '>', $outfile;
	print $out $html;
	return 1;
}

sub _handle_text {
	my ( $parser, $text ) = @_;
	if ( $parser->{__in_name} ) {
		$parser->{__abstract} = $text;
		delete $parser->{__in_name};
	}
	if ( $text eq 'NAME' ) {
		$parser->{__in_name} = 1;
	}

	$parser->SUPER::_handle_text($text);
}



1;
