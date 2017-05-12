#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

use_ok 'Text::CaffeinatedMarkup::HTMLFormatter';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

	can_ok('Text::CaffeinatedMarkup::HTMLFormatter',qw|format _match_tag|);

	test_simple();
	test_headers();
	test_links();
	test_images();
	test_breaks();
	test_rows_and_columns();
	test_full_doc_1();

	test_blockquotes();

	# TESTS TO DO
	# .. html escape
	# .. entity escape

done_testing();


# ==============================================================================

sub test_simple {
	subtest "Simple markup test" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('**abc**'),'<p><strong>abc</strong></p>','Strong');
		is($parser->format('//abc//'),'<p><em>abc</em></p>','Emphasis');
		is($parser->format('__abc__'),'<p><u>abc</u></p>','Underline');
		is($parser->format('--abc--'),'<p><del>abc</del></p>','Delete');
	};
}

# ------------------------------------------------------------------------------

sub test_headers {
	subtest "Simple markup test" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('# My header'),	"\n<h1>My header</h1>\n",'Header 1');
		is($parser->format('## My header'),	"\n<h2>My header</h2>\n",'Header 2');
		is($parser->format('### My header'),"\n<h3>My header</h3>\n",'Header 3');
	};
}

# ------------------------------------------------------------------------------

sub test_links {
	subtest "Simple links" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('[[http://here.com]]'),
			'<a href="http://here.com" target="_new">http://here.com</a>',
			'Simple link - no text');

		is($parser->format('[[http://here.com|HERE]]'),
			'<a href="http://here.com" target="_new">HERE</a>',
			'Simple link - with text');
	};
}

# ------------------------------------------------------------------------------

sub test_images {
	subtest "Simple images" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('{{image.jpg}}'), '<img src="image.jpg">', 'Relative image');
		is($parser->format('{{http://a.com/image.jpg}}'), '<img src="http://a.com/image.jpg">', 'Absolute image');
	};

	subtest "Images with align options" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('{{i.jpg|<<}}'), '<img src="i.jpg" class="pulled-left">',  'Pull left');
		is($parser->format('{{i.jpg|>>}}'), '<img src="i.jpg" class="pulled-right">', 'Pull right');
		is($parser->format('{{i.jpg|><}}'), '<img src="i.jpg" class="centered">', 	  'Centered');
		is($parser->format('{{i.jpg|<>}}'), '<img src="i.jpg" class="stretched">', 	  'Stretched');
	};

	subtest "Images with width options" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('{{i.jpg|W10}}'), '<img src="i.jpg" width="10px">', 'Width 10');
		is($parser->format('{{i.jpg|W9}}'),  '<img src="i.jpg" width="9px">',  'Width 9');		
	};

	subtest "Images with height options" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('{{i.jpg|H10}}'), '<img src="i.jpg" height="10px">', 'Height 10');
		is($parser->format('{{i.jpg|H9}}'),  '<img src="i.jpg" height="9px">',  'Height 9');		
	};

	subtest "Images with mixed options" => sub {
		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		is($parser->format('{{i.jpg|<<,W10,H11}}'),
			'<img src="i.jpg" class="pulled-left" width="10px" height="11px">',
			'All options');
	};
}

# ------------------------------------------------------------------------------

sub test_breaks {
	subtest "Test breaks" => sub {

		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;
		
		subtest "Simple single breaks" => sub {
			is $parser->format("Something\nbroken\ntwice"),
			   '<p>Something<br>broken<br>twice</p>',
			   'one line broken twice';
		};

		subtest "Paragraph breaks" => sub {
			is $parser->format("A paragraph\n\nThen another"),
			   qq|<p>A paragraph</p>\n<p>Then another</p>|,
			   'one paragraph then another';

			is $parser->format("A paragraph\n\n\n\nThen another after 4 breaks"),
			   qq|<p>A paragraph</p>\n<p>Then another after 4 breaks</p>|,
			   'one paragraph then another after 4 breaks';

			is $parser->format("A paragraph\n\n\n\n\nThen another after 5 breaks"),
			   qq|<p>A paragraph</p>\n<p>Then another after 5 breaks</p>|,
			   'one paragraph then another after 5 breaks';
		};

	};
}

# ------------------------------------------------------------------------------

sub test_rows_and_columns {
	subtest "Test rows and columns" => sub {

		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;

		subtest "Simple rows and columns" => sub {
			is $parser->format(qq!==\n||One column\n||Another column\n==!),
			   qq|<div class="clearfix col-2">\n<div class="column">\n<p>One column</p>\n</div>\n<div class="column">\n<p>Another column</p>\n</div>\n</div>\n|,
			   'two column row';

			is $parser->format(qq!==\n||One column\n||Another column\n||And another\n==!),
			   qq|<div class="clearfix col-3">\n<div class="column">\n<p>One column</p>\n</div>\n<div class="column">\n<p>Another column</p>\n</div>\n<div class="column">\n<p>And another</p>\n</div>\n</div>\n|,
			   'three column row';

			is $parser->format(qq!==\n||a\n==\n==\n||b\n==!),
			   qq|<div class="clearfix col-1">\n<div class="column">\n<p>a</p>\n</div>\n</div>\n<div class="clearfix col-1">\n<div class="column">\n<p>b</p>\n</div>\n</div>\n|,
			   'row after row'
		};

		subtest "Row in paragraphs" => sub {
			is 	$parser->format("para1\n==\n||Col\n==\npara2"),
				qq|<p>para1</p>\n<div class="clearfix col-1">\n<div class="column">\n<p>Col</p>\n</div>\n</div>\n<p>para2</p>|,
				'correct in and out of paragraphs'
		};

		subtest "Error states" => sub {
			throws_ok {$parser->format(qq!==\nOops!)}
			          qr/Unexpected char at start of row data/,
			          'parse error thrown with bad column start';

			throws_ok {$parser->format(qq!==\n|Almost!)}
					  qr/Unexpected char in first column tag/,
   					  'parse error thrown with bad column start (bad sequence)';

			throws_ok {$parser->format(qq!==\n||abc\n|!)}
					  qr/Unexpected end of data in column tag/,
					  'parse error thrown with bad column start (unexpected eof)';

			throws_ok {$parser->format(qq!==\n||abc\n||end early!)}
					  qr/Unexpected end of data in column data/,
					  'parse error thrown with unexpected eof';

		};

		subtest "Incomplete sequence" => sub {
			is $parser->format(qq!==Not a row!),
			   '<p>==Not a row</p>',
			   'plain char sequence';

		};

	};
}

# ------------------------------------------------------------------------------

sub test_blockquotes {
	subtest "Test blockquotes" => sub {

		my $parser = Text::CaffeinatedMarkup::HTMLFormatter->new;

		is $parser->format('""Very wise quote""'),
		   qq|<blockquote>Very wise quote</blockquote>|,
		   'quote marked up as expected (no cite)';

		is $parser->format('""Very wise quote|A N Other""'),
		   qq|<blockquote>Very wise quote<cite>A N Other</cite></blockquote>|,
		   'quote marked up as expected (no cite)';
	};
}

# ------------------------------------------------------------------------------

sub test_full_doc_1 {
	subtest "Full doc #1" => sub {

		my $input_pml = <<EOT
Yup, we're here! **Caffeinated Panda Creations** has launched the first phase of our new website.

Right now as you can see the blog is up and running and we'll be using it to keep you up to date with projects, events we're involved with, and new features coming to the site. Of course we'll still be streaming updates and content on [[http://facebook.com/caffeinatedpandacreations|facebook]] and [[http://twitter.com/cafpanda|twitter]] as well so come and join us there too!

As time goes on we'll be adding new sections to the website so stay tuned for updates. Upcoming soon will be more details on our creations and services, so here's some things to whet your appetite!
==
||
## Custom Cyberfalls
{{cyberfalls.jpg|<<,H100,W130}}Cyberfalls for all your cybergoth and dance needs, at Caffeinated Panda Creations we specialise in custom designs and sets with [[https://www.google.co.uk/search?q=el+wire&safe=off&tbm=isch|EL-wire]] installations.

Whether you're looking for a themed set for a special occassion or straight forward cyber-chic, get in touch and we'll be happy to work with you!
||
## 3D Printing
{{makerbot.jpg|<<,H100,W130}}We here at Caffeinated Panda Creations are the proud owners of a [[http://store.makerbot.com/replicator2.html|Makerbot Replicator 2]] 3D printer.

As well as using it for our creations we can also offer a bespoke printing service. Design your own objects or let us work with you to create and realise your vision in high quality PLA plastic.
==
==
||
## Emporia
{{etsy.jpg|<<,H100,W130}}Over the next few months we'll be opening our online stores where we'll be selling some of our premade and customisable pieces along with t-shirts and other apparel.
||
## Costuming
{{mask.jpg|<<,H100,W130}}The panda team are keen costumers and going forward will be working on several exciting cosplaying projects for ourselves and others.

We'll also be keeping you up to date on where we'll be appearing and giving details on how we can work with you on your own costuming projects.
==
EOT
;

		my $expected_html =<<EOT
<p>Yup, we&#39;re here! <strong>Caffeinated Panda Creations</strong> has launched the first phase of our new website.</p>
<p>Right now as you can see the blog is up and running and we&#39;ll be using it to keep you up to date with projects, events we&#39;re involved with, and new features coming to the site. Of course we&#39;ll still be streaming updates and content on <a href="http://facebook.com/caffeinatedpandacreations" target="_new">facebook</a> and <a href="http://twitter.com/cafpanda" target="_new">twitter</a> as well so come and join us there too!</p>
<p>As time goes on we&#39;ll be adding new sections to the website so stay tuned for updates. Upcoming soon will be more details on our creations and services, so here&#39;s some things to whet your appetite!</p>
<div class="clearfix col-2">
<div class="column">

<h2>Custom Cyberfalls</h2>
<img src="cyberfalls.jpg" class="pulled-left" width="130px" height="100px"><p>Cyberfalls for all your cybergoth and dance needs, at Caffeinated Panda Creations we specialise in custom designs and sets with <a href="https://www.google.co.uk/search?q=el+wire&safe=off&tbm=isch" target="_new">EL-wire</a> installations.</p>
<p>Whether you&#39;re looking for a themed set for a special occassion or straight forward cyber-chic, get in touch and we&#39;ll be happy to work with you!</p>
</div>
<div class="column">

<h2>3D Printing</h2>
<img src="makerbot.jpg" class="pulled-left" width="130px" height="100px"><p>We here at Caffeinated Panda Creations are the proud owners of a <a href="http://store.makerbot.com/replicator2.html" target="_new">Makerbot Replicator 2</a> 3D printer.</p>
<p>As well as using it for our creations we can also offer a bespoke printing service. Design your own objects or let us work with you to create and realise your vision in high quality PLA plastic.</p>
</div>
</div>
<div class="clearfix col-2">
<div class="column">

<h2>Emporia</h2>
<img src="etsy.jpg" class="pulled-left" width="130px" height="100px"><p>Over the next few months we&#39;ll be opening our online stores where we&#39;ll be selling some of our premade and customisable pieces along with t-shirts and other apparel.</p>
</div>
<div class="column">

<h2>Costuming</h2>
<img src="mask.jpg" class="pulled-left" width="130px" height="100px"><p>The panda team are keen costumers and going forward will be working on several exciting cosplaying projects for ourselves and others.</p>
<p>We&#39;ll also be keeping you up to date on where we&#39;ll be appearing and giving details on how we can work with you on your own costuming projects.</p>
</div>
</div>
EOT
;

		my $formatter = Text::CaffeinatedMarkup::HTMLFormatter->new();
		my $html = $formatter->format( $input_pml );
		is( $html, $expected_html, 'HTML as expected' );

	};
	return;
}


