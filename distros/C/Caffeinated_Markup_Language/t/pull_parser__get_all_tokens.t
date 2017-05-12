#!/usr/bin/env perl

use strict;

use Test::More;
use Test::Exception;

use Readonly;
Readonly my $CLASS => 'Text::CaffeinatedMarkup::PullParser';

use_ok $CLASS;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

my $parser;

	subtest "Simple parse" => sub {
		$parser = $CLASS->new(pml => 'Simple **PML** to parse');
		my @tokens = ();
		lives_ok {@tokens = $parser->get_all_tokens()}, 'Parse without error';	
	};

	test_simple_markup();
	test_link_markup();
	test_image_markup();
	test_newline_markup();
	test_header_markup();
	test_section_break_markup();
	test_row_and_column_markup();
	test_quote_markup();


done_testing();

# ==============================================================================

sub get_tokens_string {
	my ($tokens_r) = @_;
	my @types;
	for (@$tokens_r) { push @types, $_->{type} }
	return join ',',@types;
}

# ------------------------------------------------------------------------------

sub test_simple_markup {

	subtest "Test simple markup" => sub {

		my @tokens = ();

		subtest "Strong" => sub {
			$parser = $CLASS->new(pml => 'Simple **PML** to parse');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,STRONG,STRING,STRONG,STRING', 'Strong in string' );
			is($tokens[0]->{content}, 'Simple ',   'Token #1 correct text'	);
			is($tokens[1]->{type}, 	  'STRONG',    'Token #2 is STRONG'		);
			is($tokens[2]->{content}, 'PML', 	   'Token #3 correct text'	);
			is($tokens[3]->{type}, 	  'STRONG',    'Token #4 is STRONG'		);
			is($tokens[4]->{content}, ' to parse', 'Token #5 correct text'	);


			$parser = $CLASS->new(pml => '**Strong** at start');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRONG,STRING,STRONG,STRING', 'Strong at start' );

			$parser = $CLASS->new(pml => 'At the end is **Strong**');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,STRONG,STRING,STRONG', 'Strong at end' );
		};

		subtest "Emphasis" => sub {
			$parser = $CLASS->new(pml => 'With //emphasis// in middle');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,EMPHASIS,STRING,EMPHASIS,STRING', 'Emphasis in string' );

			$parser = $CLASS->new(pml => '//Emphasis// at start');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'EMPHASIS,STRING,EMPHASIS,STRING', 'Emphasis at start' );

			$parser = $CLASS->new(pml => 'At the end is //emphasis//');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,EMPHASIS,STRING,EMPHASIS', 'Emphasis at end' );
		};

		subtest "Underline" => sub {
			$parser = $CLASS->new(pml => 'With __underline__ in middle');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,UNDERLINE,STRING,UNDERLINE,STRING', 'Underline in string' );

			$parser = $CLASS->new(pml => '__underline__ at start');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'UNDERLINE,STRING,UNDERLINE,STRING', 'Underline at start' );

			$parser = $CLASS->new(pml => 'At the end is __underline__');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,UNDERLINE,STRING,UNDERLINE', 'Underline at end' );
		};

		subtest "Del" => sub {
			$parser = $CLASS->new(pml => 'With --del-- in middle');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,DEL,STRING,DEL,STRING', 'Del in string' );

			$parser = $CLASS->new(pml => '--del-- at start');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'DEL,STRING,DEL,STRING', 'Del at start' );

			$parser = $CLASS->new(pml => 'At the end is --del--');
			@tokens = $parser->get_all_tokens;
			is( get_tokens_string(\@tokens), 'STRING,DEL,STRING,DEL', 'Del at end' );
		};
	};
	return;
}

# ------------------------------------------------------------------------------

sub test_link_markup {
	subtest "Test link markup" => sub {

		my @tokens = ();

		subtest "Simple link" => sub {
			$parser = $CLASS->new(pml => "Go here [[http://www.google.com]] it's cool");
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING,LINK,STRING','Link with just href');
			is($tokens[1]->{href}, 'http://www.google.com', 'Href set ok');
			is($tokens[1]->{text}, '', 'Text is null');
		};

		subtest "Simple link with text" => sub {
			$parser = $CLASS->new(pml => "Go here [[http://www.google.com|Google]] it's cool");
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING,LINK,STRING','Link with text');
			is($tokens[1]->{href}, 'http://www.google.com', 'Href set ok');
			is($tokens[1]->{text}, 'Google', 'Text set ok');
		};

	};
	return;
}

# ------------------------------------------------------------------------------

sub test_image_markup {
	subtest "Test image markup" => sub {

		my @tokens = ();

		subtest "Simple image" => sub {
			$parser = $CLASS->new(pml => "Look at this {{cat.jpg}} Nice huh?");
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING,IMAGE,STRING','Image with just src');
			is($tokens[1]->{src}, 'cat.jpg', 'Src set ok');
			is($tokens[1]->{options}, '', 'Options is null');
		};

		subtest "Simple image with options" => sub {
			$parser = $CLASS->new(pml => "Look at this {{cat.jpg|>>,W29}} Nice huh?");
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING,IMAGE,STRING','Image with just src');
			is($tokens[1]->{src}, 'cat.jpg', 'Src set ok');
			is($tokens[1]->{options}, '>>,W29', 'Options set ok');
		};

	};
	return;
}

# ------------------------------------------------------------------------------

sub test_header_markup {
	subtest "Test header markup" => sub {

		my @tokens = ();

		subtest "Simple headers 1-6" => sub {
			$parser = $CLASS->new(pml => qq|# Header level 1|);
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'HEADER','Header token');
			is($tokens[0]->{level},1,'Header level is 1');
			is($tokens[0]->{text},'Header level 1', 'Header text is correct');
		};

		subtest "In line becomes string" => sub {
			$parser = $CLASS->new(pml => qq|String then # Header level 1|);
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING','Just a string token');
			is($tokens[0]->{content},'String then # Header level 1', 'Content correct');
		};

	};
}

# ------------------------------------------------------------------------------

sub test_newline_markup {
	subtest "Test newline markup" => sub {

		my @tokens = ();

		subtest "Single newline" => sub {
			$parser = $CLASS->new(pml => "First line\nSecond line");
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING,NEWLINE,STRING','Single newline in string');
		};

		subtest "Double newline" => sub {
			$parser = $CLASS->new(pml => "First line\n\nSecond line");
			@tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'STRING,NEWLINE,NEWLINE,STRING','Double newline in string');
		};

	};
	return;
}

# ------------------------------------------------------------------------------

sub test_row_and_column_markup {
	subtest "Test row and column markup" => sub {

		subtest "Simple rows" => sub {

			subtest "Single column" => sub {
				$parser = $CLASS->new(pml => "==\n||Column\n==\n");
				my @tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,STRING,ROW',
					'Row with single column tokens ok'
				);
			};

			subtest "Two column" => sub {
				$parser = $CLASS->new(pml => "==\n||Column||Column\n==\n");
				my @tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,STRING,COLUMN,STRING,ROW',
					'Row with double column tokens ok'
				);
			};

		};

		subtest "Row following row" => sub {
			$parser = $CLASS->new(pml => "==\n||Column||Column\n==\n==\n||Column2||Column2\n==\n");
			my @tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),
				'ROW,COLUMN,STRING,COLUMN,STRING,ROW,ROW,COLUMN,STRING,COLUMN,STRING,ROW',
				'Row with double column tokens ok'
			);
		};

		subtest "Columns with markup" => sub {
			my @tokens = ();
			$parser = $CLASS->new(pml => "==\n||There is something **strong** here\n||Blah\n==");
			@tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,STRING,STRONG,STRING,STRONG,STRING,COLUMN,STRING,ROW',
					'Column with strong markup'
				);

			$parser = $CLASS->new(pml => "==\n||There is something //emphasised// here\n||Blah\n==");
			@tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,STRING,EMPHASIS,STRING,EMPHASIS,STRING,COLUMN,STRING,ROW',
					'Column with emphasis markup'
				);

			$parser = $CLASS->new(pml => "==\n||There is something __underlined__ here\n||Blah\n==");
			@tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,STRING,UNDERLINE,STRING,UNDERLINE,STRING,COLUMN,STRING,ROW',
					'Column with Underline markup'
				);

			$parser = $CLASS->new(pml => "==\n||There is something --deleted-- here\n||Blah\n==");
			@tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,STRING,DEL,STRING,DEL,STRING,COLUMN,STRING,ROW',
					'Column with delete markup'
				);

			$parser = $CLASS->new(pml => "==\n||[[http://cafpanda.com]]||Blah\n==");
			@tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,LINK,COLUMN,STRING,ROW',
					'Column with link markup'
				);

			$parser = $CLASS->new(pml => "==\n||{{panda.png}}||Blah\n==");
			@tokens = $parser->get_all_tokens;
				is(get_tokens_string(\@tokens),
					'ROW,COLUMN,IMAGE,COLUMN,STRING,ROW',
					'Column with image markup'
				);
		};
	};
}

# ------------------------------------------------------------------------------

sub test_quote_markup {
	subtest "Test quote markup" => sub {

		my @tokens = ();

		subtest "Simple quotes" => sub {

			subtest "Simple quote - no cite" => sub {
				$parser = $CLASS->new(pml => '""A wise man once said""');
				@tokens = $parser->get_all_tokens;
				is get_tokens_string(\@tokens), 'QUOTE', 'got quote token';
				is $tokens[0]->{body}, 'A wise man once said', 'body ok';
				is $tokens[0]->{cite}, '', 'no cite as expected';
			};

			subtest "Simple quote - with cite" => sub {
				$parser = $CLASS->new(pml => '""A wise man once said|Some guy""');
				@tokens = $parser->get_all_tokens;
				is get_tokens_string(\@tokens), 'QUOTE', 'got quote token';
				is $tokens[0]->{body}, 'A wise man once said', 'body ok';
				is $tokens[0]->{cite}, 'Some guy', 'cite as expected';
			};

		};

		subtest "Quotes nested in other blocks" => sub {

			subtest "Root level" => sub {
				$parser = $CLASS->new(pml => 'This is true: ""A wise man once said"" Is it not?');
				@tokens = $parser->get_all_tokens;
				is get_tokens_string(\@tokens), 'STRING,QUOTE,STRING', 'got quote token with strings';
				is $tokens[1]->{body}, 'A wise man once said', 'body ok';
				is $tokens[1]->{cite}, '', 'no cite as expected';
			};

			subtest "In a column" => sub {
				$parser = $CLASS->new(pml => qq!==\n||""A wise man once said""\n==!);
				@tokens = $parser->get_all_tokens;
				is get_tokens_string(\@tokens), 'ROW,COLUMN,QUOTE,ROW', 'got quote token with strings';
				is $tokens[2]->{body}, 'A wise man once said', 'body ok';
				is $tokens[2]->{cite}, '', 'no cite as expected';
			};
		};

	};
}

# ------------------------------------------------------------------------------

sub test_section_break_markup {
	subtest "Test section_break markup" => sub {

		subtest "Simple section break" => sub {
			$parser = $CLASS->new(pml => '~~');
			my @tokens = $parser->get_all_tokens;
			is(get_tokens_string(\@tokens),'SECTIONBREAK','Section break');	
		};
	};
}

# ------------------------------------------------------------------------------
