#!perl
use v5.36;
use utf8;
use Test::More;
use Test::Mojo;
use File::Temp;
use Log::Any::Adapter 'TAP';
use App::SlideServer 'mojo2logany';

my $nanika= chr(0x4F55).chr(0x304B);

sub tempfile_containing($content, @opts) {
	my $f= File::Temp->new(@opts);
	binmode($f, ':encoding(UTF-8)');
	$f->print(@_);
	$f->seek(0,0);
	$f;
}

my $html= <<~HTML;
	<html>
	<head><title>Test1</title></head>
	<body><div class="slides">
		<div class="slide">
			<h2>$nanika</h2>
			<ul>
			<li>Point 1</li>
			<li>Point 2</li>
			</ul>
		</div>
	</div></body>
	</html>
	HTML

my $html_f= tempfile_containing($html, SUFFIX => '.html');

my $md= <<~MD;
	## $nanika
	
	  * Point 1
	  * Point 2
	
	MD

my $md_f= tempfile_containing($md, SUFFIX => '.md');

for (
	[ html_scalar => App::SlideServer->new(slides_source_file => \$html,    log => mojo2logany(), presenter_key => 'x') ],
	[ html_fname  => App::SlideServer->new(slides_source_file => "$html_f", log => mojo2logany(), presenter_key => 'x') ],
	[ html_handle => App::SlideServer->new(slides_source_file => $html_f,   log => mojo2logany(), presenter_key => 'x') ],
	[ md_scalar   => App::SlideServer->new(slides_source_file => \$md,      log => mojo2logany(), presenter_key => 'x') ],
	[ md_fname    => App::SlideServer->new(slides_source_file => "$md_f",   log => mojo2logany(), presenter_key => 'x') ],
	[ md_handle   => App::SlideServer->new(slides_source_file => $md_f,     log => mojo2logany(), presenter_key => 'x') ],
) {
	my ($name, $ss)= @$_;
	subtest $name => sub {
		like( $ss->load_slides_html, qr/$nanika/, 'contains high chars' );
		my $slides= $ss->slides_dom;
		is( scalar @$slides, 1, 'one slide built' )
			or diag explain $ss->load_slides_html, explain $slides;
		like( "$slides->[0]", qr|<h2.*?>$nanika</h2>|, 'slide contains expected heading' );
	};
}

done_testing;
