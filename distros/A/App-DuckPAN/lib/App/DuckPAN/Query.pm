package App::DuckPAN::Query;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: Main application/loop for duckpan query
$App::DuckPAN::Query::VERSION = '1021';
use Moo;
use Data::Printer return_value => 'dump';
use POE qw( Wheel::ReadLine );
use Try::Tiny;
use Path::Tiny;
use App::DuckPAN::Fathead;
use open qw/:std :utf8/;

# Entry into the module.
sub run {
	my ( $self, $app, $blocks ) = @_;

	# Here so that travis builds will pass on github
	require DDG::Request;
	DDG::Request->import;
	require DDG::Test::Location;
	DDG::Test::Location->import;
	require DDG::Test::Language;
	DDG::Test::Language->import;

	# Main session. All events declared have equivalent subs.
	POE::Session->create(
		package_states => [
			$self => [qw(_start _stop _get_user_input _got_user_input _run_query)]
		],
		args => [$app, $blocks] # passed to _start
	);
	POE::Kernel->run();

	return 0;
}

# Initialize the main session. Called once by default.
sub _start {
	my ($k, $h, $app, $blocks) = @_[KERNEL, HEAP, ARG0, ARG1];

	my $history_path = $app->cfg->cache_path->child('query_history');

	# Session that handles user input
	my $powh_readline = POE::Wheel::ReadLine->new(
		InputEvent => '_got_user_input'
	);
	$powh_readline->bind_key("C-\\", "interrupt");
	$powh_readline->read_history($history_path);
	$powh_readline->put('(Empty query for ending test)');

	# Store in the heap for use in other events
	@$h{qw(app blocks console history_path)} = ($app, $blocks, $powh_readline, $history_path);

	$k->sig(TERM => '_stop');
	# Queue user input event
	$k->yield('_get_user_input');
}

sub _default { warn "Unhandled event - $_[ARG0]" }

# The session is about to stop.  Ensure that the ReadLine object is
# deleted, so it can place your terminal back into a sane mode.  This
# function is triggered by POE's "_stop" event.
sub _stop {
	undef $_[HEAP]->{console}; #powh_readline;
	exit;
}

# Event to handle user input, triggered by ReadLine
sub _got_user_input {
	my ($k, $h, $input) = @_[KERNEL, HEAP, ARG0];

	# If we have input, send it off to be processed
	if($input){
		my ($console, $history_path) = @$h{qw(console history_path)};

		$console->put("  You entered: $input");
		$console->addhistory($input);
		$console->write_history($history_path);
		$k->yield(_run_query => $input); # this yield keeps the loop going
	}
	else{
		$h->{console}->put('\\_o< Thanks for testing!');
	}
	# falling through here without queuing an event ends the app.
}

# Event that prints the prompt and waits for input.
sub _get_user_input {
	$_[HEAP]{console}->get('Query: ');
}

# Event that processes the query
sub _run_query {
	my ($k, $h, $query) = @_[KERNEL, HEAP, ARG0];

	my ($app, $blocks) = @$h{qw{app blocks}};
	Encode::_utf8_on($query);

	my $repo = $app->get_ia_type;

	try {
		if ($repo->{name} eq "Fathead") {
			my $output_txt = $app->fathead->output_txt;
			if (my $result = $app->fathead->structured_answer_for_query($query)) {
				$app->emit_info('---', "Match found: $output_txt", p($result, colored => $app->colors), '---');
			}
			else {
				$app->emit_error('Sorry, no matches found in output.txt');
			}
		}
		else {
			my $request = DDG::Request->new(
				query_raw => $query,
				location => test_location_by_env(),
				language => test_language_by_env(),
			);
			my $hit;
			# Iterate through the IAs passing each the query request
			for my $b (@$blocks) {
				for ($b->request($request)) {
					$hit = 1;
					$app->emit_info('---', p($_, colored => $app->colors), '---');
				}
			}
			unless ($hit) {
				$app->emit_info('Sorry, no Instant Answers returned a result')
			}
		}
	}
	catch {
		my $error = $_;
		if ($error =~ m/Malformed UTF-8 character/) {
			$app->emit_info('You got a malformed utf8 error message. Normally' .
				' it means that you tried to enter a special character at the query' .
				' prompt but your interface is not properly configured for utf8.' .
				' Please check the documentation for your terminal, ssh client' .
				' or other client used to execute duckpan.'
			);
		}
		$app->emit_info("Caught error: $error");
	};

	# Enqueue input event
	$k->yield('_get_user_input');
}

1;

__END__

=pod

=head1 NAME

App::DuckPAN::Query - Main application/loop for duckpan query

=head1 VERSION

version 1021

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>, Zach Thompson <zach@duckduckgo.com>, Zaahir Moolla <moollaza@duckduckgo.com>, Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
