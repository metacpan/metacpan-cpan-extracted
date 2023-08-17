#!perl
use v5.36;
use utf8;
use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Log::Any::Adapter 'TAP';
use App::SlideServer 'mojo2logany';

my $md= <<~MD;
	<title>Test</title>
	<head><style>body { color: white; }</style></head>
	<script>window.alert("x")</script>

	## Heading 2
	
	  * Bullet 1
	  * Bullet 2
	
	### Heading 3
	
	    Code Block
		More Code
	
	<hr>
	
	    Code block 2
		More Code
	
	<notes>Some Notes</notes>
	
	<h1>Heading 1</h1>
	
	<code>Code block 3
	</code>
	MD

my $ss= App::SlideServer->new(slides_source_file => \$md, log => mojo2logany(), presenter_key => 'x');

eval {
	my @slides= $ss->slides_dom->@*;
	is( scalar(@slides), 4, '4 slides' ) or die;
	
	is( $slides[0]->at('div.slide h2')->text, 'Heading 2' );
	is( $slides[0]->at('div.slide ul li')->text, 'Bullet 1' );
	
	is( $slides[1]->at('div.slide h3')->text, 'Heading 3' );
	like( $slides[1]->at('div.slide code')->text, qr/More Code/ );
	
	like( $slides[2]->at('div.slide code')->text, qr/Code block 2/ );
	like( $slides[2]->at('div.slide pre.notes')->text, qr/Some Notes/ );
	
	like( $slides[3]->at('div.slide h1')->text, qr/Heading 1/ );
	like( $slides[3]->at('div.slide code')->text, qr/Code block 3/ );
	
	done_testing;
	1;
}
or diag explain join "\n", $@, $ss->slides_dom->@*;

