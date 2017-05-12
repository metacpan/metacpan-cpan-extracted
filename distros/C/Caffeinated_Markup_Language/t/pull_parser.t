#!/usr/bin/env perl

use strict;

use Test::More;
use Test::Exception;


use Readonly;
Readonly my $CLASS => 'Text::CaffeinatedMarkup::PullParser';

use_ok $CLASS;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);


my $parser = undef;

subtest "Instantiation" => sub {

	throws_ok { $CLASS->new() }
		qr/Must supply 'pml' to Text::CaffeinatedMarkup::PullParser/,
		'new() dies with no pml supplied';

	lives_ok { $parser = new_ok $CLASS, ['pml'=>'Some PML'] }
		'new() lives ok with args supplied';

	is( scalar @{$parser->pml_chars}, 8,'Input PML split into 8 chars');
};


subtest "Internal methods" => sub {

	subtest "_create_token" => sub {
		throws_ok { $parser->_create_token() }
			qr/Encountered parse error \[No token data passed to _create_token\(\)\]/,
			'_create_token() dies when no token data passed';

		# No previous token
		$parser->temporary_token(undef);
		$parser->_create_token({type=>'STRING'});
		is($parser->token, undef, 'No previous token');
		is_deeply($parser->temporary_token,{type=>'STRING'}, 'New token created');

		# Now have previous token
		$parser->_create_token({type=>'LINK'});		
		is_deeply($parser->token, {type=>'STRING'}, 'Emit previous token' );
		is_deeply($parser->temporary_token,{type=>'LINK'}, 'New token created');

		# Clear context on new token
		$parser->temporary_token_context('href');
		$parser->_create_token({type=>'STRING'});
		is($parser->temporary_token_context, undef, 'Context cleared on create new');
	};

	# -------------------------------------------

	subtest "_append_to_string_token" => sub {
		# No previous string char
		$parser->token(undef);
		$parser->temporary_token(undef);
		$parser->_append_to_string_token('x');
		is_deeply(
			$parser->temporary_token,
			{type=>'STRING',content=>'x'},
			'No previous - set to new string token'
		);

		# Has previous string char
		$parser->_append_to_string_token('y');
		is_deeply(
			$parser->temporary_token,
			{type=>'STRING',content=>'xy'},
			'Appends to previous existing'
		);
		is($parser->token, undef, 'No token output');

		# Has previous
		$parser->temporary_token( {type=>'LINK'} );
		$parser->_append_to_string_token('x');
		is_deeply(
			$parser->temporary_token,
			{type=>'STRING',content=>'x'},
			'Create new token'
		);
		is_deeply($parser->token,{type=>'LINK'},'Get previous token');
	};

	# -------------------------------------------

	subtest "_switch_state" => sub {
		# No current state
		$parser->state(undef);
		$parser->_switch_state('data');
		is($parser->state,'data','Switched to data state');

		# New state 
		$parser->_switch_state('end_of_data');
		is($parser->state,'end_of_data','Switched to end_of_data state');
	};

	# -------------------------------------------

	subtest "_raise_parse_error" => sub {
		throws_ok { $parser->_raise_parse_error('my error') }
			qr/Encountered parse error \[my error]/,
			"Dies as expected";
	};

	# -------------------------------------------

	subtest "_discard_token" => sub {
		# Run ok with no token to discard
		$parser->temporary_token(undef);
		$parser->temporary_token_context(undef);
		lives_ok {$parser->_discard_token}
			"_discard_token() runs ok when no previous token";

		# Discard ok
		$parser->temporary_token({type=>'STRING',content=>'xyz'});
		$parser->temporary_token_context('some-context');
		lives_ok {$parser->_discard_token}
			"_discard_token() runs ok with previous token";
		is($parser->temporary_token,		undef, 'Token discarded');
		is($parser->temporary_token_context,undef, 'Token context discarded');
	};

	# -------------------------------------------

	subtest "data context" => sub {
		$parser->data_context([]);

		is $parser->_get_data_context, 'data', 'default context is "data"';

		$parser->_push_data_context('context1');
		$parser->_push_data_context('context2');
		is $parser->_get_data_context, 'context2', 'context set as expected';

		$parser->_pop_data_context;
		is $parser->_get_data_context, 'context1', 'context set as expected';

		$parser->_pop_data_context;		
		is $parser->_get_data_context, 'data', 'back to "data"';

		$parser->_pop_data_context;
		is $parser->_get_data_context, 'data', 'pop on empty is still "data"';

		$parser->_push_data_context('context1');
		$parser->_push_data_context('context2');
		$parser->_clear_data_context;
		is $parser->_get_data_context, 'data', 'context is "data" after clear';
	};

};


can_ok( $parser, qw|get_all_tokens get_next_token|);

done_testing();
