#!/usr/bin/env perl
use warnings;
use 5.026;
use FindBin ();
use Path::Class qw/dir/;
use URI ();
use HTTP::Tiny ();
use Text::CleanFragment qw/clean_fragment/;
use Regexp::Common qw/balanced delimited/;
use JSON::MaybeXS ();
use XML::LibXML ();
use Data::Dump qw/dd/;

# Badge-Simple 0.01 had a ton of CPAN Testers failures
# This gets the reports and tries to figure out what's up

my $VERBOSE = 0;

my %tbl = ();
sub analyze {
	my $report = shift;
	$tbl{total}++;
	if ($report=~/\bbadge: no font specified and failed to load default font\b/)
		{ $tbl{'fontfile issue'}++ } # hopefully fixed by d06a44aa37945b3b9c
	else {
		my $width_issue=0;
		while ( $report=~m{ ^ \h* \# \h+ Failed\ test\ '([^']*\.svg)' \h* \n
				^ \h* \# \h+ at \N+ \n
				^ \s* \# \s+ got: \s+ ($RE{delimited}{-delim=>"'"}) \h* \n
				^ \s* \# \s+ expected: \s+ ($RE{delimited}{-delim=>"'"}) \h* $ }msxg ) {
			my ($file,$svgbad,$svgexp) = ($1,$2,$3);
			s/\A'(.+)'\z/$1/ or die $_ for $svgbad,$svgexp;
			$tbl{svg_expexted}{$file} = $svgexp;
			$tbl{svg_bad}{$file}{$svgbad}++;
			$width_issue++;
		}
		if ($width_issue)
			{ $tbl{'width issue'}++ }
		else
			{ $tbl{'unknown failures'}{$report}++ }
	}
}
sub done_analyzing {
	dd \%tbl;
}

my $GET_CACHE = dir($FindBin::Bin,'scrape_cache'); # for sub get
$GET_CACHE->mkpath(1);

my $json = JSON::MaybeXS->new(relaxed=>1);

my $cpt_js = get('http://www.cpantesters.org/static/distro/B/Badge-Simple.js')->slurp;

$cpt_js =~ m{ \b var \s+ versions \s* = \s*
	( $RE{balanced}{-parens=>'[]'} ) \s* (?: ; | \z ) }xms
		or die $cpt_js;
my $versions = $json->decode($1);
my $version = $versions->[-1];

$cpt_js =~ m{ \b var \s+ results \s* = \s*
	( $RE{balanced}{-parens=>'{}'} ) \s* (?: ; | \z ) }xms
		or die $cpt_js;
my $reports = $json->decode($1);

say "Getting FAIL reports for $version";
for my $rep ( $reports->{$version}->@* ) {
	next unless $rep->{status} eq 'FAIL';
	my $url = URI->new('http://api.cpantesters.org/v3/report');
	$url->path_segments( $url->path_segments, $rep->{guid} );
	my $report = $json->decode( get($url,1)->slurp );
	die "id mismatch?" unless $report->{id} eq $rep->{guid};
	die "fail mismatch?" unless $report->{result}{grade} eq 'fail';
	my @out_keys = keys $report->{result}{output}->%*;
	die "unexpected keys: @out_keys" unless @out_keys==1
		&& $out_keys[0] eq 'uncategorized';
	analyze( $report->{result}{output}{uncategorized} );
}

sub get {
	my ($url,$forcecache) = @_;
	state $http = HTTP::Tiny->new();
	my $file = $GET_CACHE->file(clean_fragment("$url"));
	$VERBOSE and print "$url: ";
	if ($forcecache && -e $file) {
		# assume file name is unique and won't be modified on server
		$VERBOSE and say "Cached"; return $file;
	} # else
	my $resp = $http->mirror($url, "$file");
	my $status = "$resp->{status} $resp->{reason}";
	if ($resp->{success}) { $VERBOSE and say $status }
	else { die $status }
	return $file;
}
done_analyzing();

__END__

Extract of "Getting FAIL reports for Badge-Simple-0.01"
  "svg_bad"          => { "cpt100.svg" => { "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"131\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"131\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"89\"></rect><rect fill=\"#4c1\" height=\"20\" width=\"42\" x=\"89\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"131\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"45.5\" y=\"15\">CPAN Testers</text><text x=\"45.5\" y=\"14\">CPAN Testers</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"109\" y=\"15\">100%</text><text x=\"109\" y=\"14\">100%</text></g></svg>"     => 70,
                                            "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"132\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"132\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"89\"></rect><rect fill=\"#4c1\" height=\"20\" width=\"43\" x=\"89\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"132\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"45.5\" y=\"15\">CPAN Testers</text><text x=\"45.5\" y=\"14\">CPAN Testers</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"109.5\" y=\"15\">100%</text><text x=\"109.5\" y=\"14\">100%</text></g></svg>" => 14, },
                          "foo.svg"    => { "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"60\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"60\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"30\"></rect><rect fill=\"#e542f4\" height=\"20\" width=\"30\" x=\"30\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"60\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"16\" y=\"15\">foo</text><text x=\"16\" y=\"14\">foo</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"44\" y=\"15\">bar</text><text x=\"44\" y=\"14\">bar</text></g></svg>"     => 70,
                                            "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"61\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"61\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"30\"></rect><rect fill=\"#e542f4\" height=\"20\" width=\"31\" x=\"30\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"61\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"16\" y=\"15\">foo</text><text x=\"16\" y=\"14\">foo</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"44.5\" y=\"15\">bar</text><text x=\"44.5\" y=\"14\">bar</text></g></svg>" => 14, },
                          "hello.svg"  => { "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"87\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"87\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"39\"></rect><rect fill=\"#dfb317\" height=\"20\" width=\"48\" x=\"39\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"87\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"20.5\" y=\"15\">Hello</text><text x=\"20.5\" y=\"14\">Hello</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"62\" y=\"15\">World!</text><text x=\"62\" y=\"14\">World!</text></g></svg>" => 70,
                                            "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"87\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"87\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"40\"></rect><rect fill=\"#dfb317\" height=\"20\" width=\"47\" x=\"40\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"87\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"21\" y=\"15\">Hello</text><text x=\"21\" y=\"14\">Hello</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"62.5\" y=\"15\">World!</text><text x=\"62.5\" y=\"14\">World!</text></g></svg>" => 14, }, },
  "svg_expexted"     => { "cpt100.svg" =>   "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"129\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"129\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"88\"></rect><rect fill=\"#4c1\" height=\"20\" width=\"41\" x=\"88\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"129\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"45\" y=\"15\">CPAN Testers</text><text x=\"45\" y=\"14\">CPAN Testers</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"107.5\" y=\"15\">100%</text><text x=\"107.5\" y=\"14\">100%</text></g></svg>",
                          "foo.svg"    =>   "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"59\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"59\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"29\"></rect><rect fill=\"#e542f4\" height=\"20\" width=\"30\" x=\"29\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"59\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"15.5\" y=\"15\">foo</text><text x=\"15.5\" y=\"14\">foo</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"43\" y=\"15\">bar</text><text x=\"43\" y=\"14\">bar</text></g></svg>",
                          "hello.svg"  =>   "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"20\" width=\"83\"><linearGradient id=\"smooth\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"></stop><stop offset=\"1\" stop-opacity=\".1\"></stop></linearGradient><clipPath id=\"round\"><rect fill=\"#fff\" height=\"20\" rx=\"3\" width=\"83\"></rect></clipPath><g clip-path=\"url(#round)\"><rect fill=\"#555\" height=\"20\" width=\"38\"></rect><rect fill=\"#dfb317\" height=\"20\" width=\"45\" x=\"38\"></rect><rect fill=\"url(#smooth)\" height=\"20\" width=\"83\"></rect></g><g fill=\"#fff\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\" text-anchor=\"middle\"><text fill=\"#010101\" fill-opacity=\".3\" x=\"20\" y=\"15\">Hello</text><text x=\"20\" y=\"14\">Hello</text><text fill=\"#010101\" fill-opacity=\".3\" x=\"59.5\" y=\"15\">World!</text><text x=\"59.5\" y=\"14\">World!</text></g></svg>", },

