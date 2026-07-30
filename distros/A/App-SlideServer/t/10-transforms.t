#!perl
use v5.36;
use utf8;
use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Log::Any::Adapter 'TAP';
use App::SlideServer 'mojo2logany';

subtest notes => sub {
	my $ss= App::SlideServer->new(slides_source_file => \<<~END, log => mojo2logany(), presenter_key => 'x');
      <notes>
      Test Line 1
      Test Line 2
      </notes>
      END
	unless (eval {
		my @slides= $ss->slides_dom->@*;
		is( scalar(@slides), 1, '1 slide' ) or die;
		is( $slides[0]->at('div.slide pre.notes')->text, "\nTest Line 1\nTest Line 2\n" );
	}) {
		diag explain join "\n", $@, $ss->slides_dom->@*;
		die $@;
	}
};

subtest head_tags => sub {
	my $ss= App::SlideServer->new(slides_source_file => \<<~END, log => mojo2logany(), presenter_key => 'x');
      <title>Test</title>
      <meta id="from-src" charset="UTF-8" />
      <link id="from-src" rel="stylesheet" />
      <h3>Slide Header</h3>
      <head>
        <script id="from-src">x=1</script>
      </head>
      Slide Content
      END
	unless (eval {
		my @slides= $ss->slides_dom->@*;
		is( scalar(@slides), 1, '1 slide' ) or die;
		is( $slides[0]->at('head'), undef, 'no HEAD in slide' );
		is( $slides[0]->at('script'), undef, 'no SCRIPT in slide' );

		my $head= $ss->page_dom->at('head');
		is( $head->at('title')->text, "Test", "title[text]" );
		is( $head->at('link')->attr->{rel}, "stylesheet", "rel[stylesheet]" );
		is( $head->at('meta[id=from-src]')->attr->{charset}, "UTF-8", "meta[charset]" );
		is( $head->at('script[id=from-src]')->text, "x=1", "script[text]" );
	}) {
		diag explain join "\n", $@, $ss->page_dom, $ss->slides_dom->@*;
		die $@;
	}
};

done_testing;
