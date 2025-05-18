use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Datastar::SSE qw/:fragment_merge_modes/;
use HTTP::Entity::Parser;
use List::Util qw/maxstr/;

my $app = sub {
	my $env = shift;
	my $request = Plack::Request->new($env);
	my $parser = $request->request_body_parser;
	$parser->register('application/json','HTTP::Entity::Parser::JSON');
	my $parameters = $request->body_parameters;

	if ($request->method eq 'GET') {
		return index_html();
	} else {
		my $params = $request->body_parameters;
		return sub {
			my $responder = shift;
			my $writer = $responder->([
				200,
				Datastar::SSE->headers,
			]);
			my @events;
			push @events, console_log( "request path : ".$request->path );
			push @events, console_table( $request->content );
			$writer->write( $_ ) for @events;
			@events = ();
			
			if ($request->path eq '/merge-fragments') {
				push @events, merge_fragments( $writer, $parameters );
			} elsif ($request->path eq '/replace-fragments') {
				push @events, replace_fragments( $writer, $parameters );
			} elsif ($request->path eq '/merge-signals') {
				push @events, merge_signals( $writer, $parameters );
			} elsif ($request->path eq '/remove-fragments') {
				push @events, remove_fragments( $writer, $parameters );
			} elsif ($request->path eq '/remove-signals') {
				push @events, remove_signals( $writer, $parameters );
			} elsif ($request->path eq '/execute-script') {
				push @events, execute_script( $writer, $parameters );
			}
			$writer->write( $_ ) for @events;
			$writer->close;
		}
	}
};

sub index_html {
	open my $fh, '<:raw', 'index.html';
	return [200, ['Content-Type' => 'text/html'], $fh];
}

sub console_log {
	my $log = shift or return;
	my $console_log = q[console.log( "%s" )];
	Datastar::SSE->execute_script( sprintf $console_log, $log );
}

sub console_table {
	my $log = shift or return;
	my $console_table = q[console.table( %s )];
	Datastar::SSE->execute_script( sprintf $console_table, $log );
}


sub merge_fragments {
	my $writer = shift;
	my $rand_name = 'rand_' . join( '', map chr( ord('a') + int rand 26 ), 0..4 );
	my $rand_value = int( rand 255 )+1;
	my $html = sprintf '<tr><td>%s</td><td>%d</td></tr>', $rand_name, $rand_value;
	my @events;
	push @events, Datastar::SSE->merge_fragments( 
		\$html => +{
			selector => '#my-table',
			merge_mode => FRAGMENT_MERGEMODE_APPEND,
		}
	);
	return @events;
}

sub replace_fragments {
	my $writer = shift;
	my $html = q[<table id="my-table"><caption>HTML</caption>\n];
	$html .= q[<tr id="header"><th>Name</th><th>Value</th></tr>\n];
	for (1..10) {
		my $rand_name = 'rand_' . join( '', map chr( ord('a') + int rand 26 ), 0..4 );
		my $rand_value = int( rand 255 )+1;
		$html .= sprintf qq[<tr idx="row_$_"><td>%s</td><td>%d</td></tr>\n], $rand_name, $rand_value;
	}
	my @events;
	push @events, Datastar::SSE->merge_fragments( 
		$html => +{
			selector => '#my-table',
			merge_mode => FRAGMENT_MERGEMODE_MORPH,
		}
	);
	return @events;
}

sub merge_signals {
	my $writer = shift;
	my $rand_signal_name = 'rand' . join( '', map chr( ord('0') + int rand 10 ), 0..4 );
	my $rand_number = int( rand 255 )+1;
	my @events;
	push @events, Datastar::SSE->merge_signals({ test => { $rand_signal_name => $rand_number }});
	# do this to update the signals JSON dump to show the new signals
	my $ctx = q[<pre id="signals" data-text="ctx.signals.JSON()"></pre>];
	push @events, Datastar::SSE->merge_fragments( 
		$ctx => +{ 
			selector => 'pre#signals', 
			merge_mode => FRAGMENT_MERGEMODE_MORPH 
		} 
	);
	return @events;
}

sub remove_fragments {
	my $writer = shift;
	my @events;
	push @events, Datastar::SSE->remove_fragments( 'ul#remove-me li:last-child' );
	return @events;
}

sub remove_signals {
	my ($writer, $signals) = @_;
	my $remove_signals = $signals->get('remove');
	return unless $remove_signals && %$remove_signals;
	my $do_remove = maxstr keys( %$remove_signals);
	warn "remove $do_remove\n";
	my @events;
	push @events, Datastar::SSE->remove_signals("remove.$do_remove");
	# do this to update the signals JSON dump to show the new signals
	my $ctx = q[<pre id="signals2" data-text="ctx.signals.JSON()"></pre>];
	push @events, Datastar::SSE->merge_fragments( 
		$ctx => +{ 
			selector => 'pre#signals2', 
			merge_mode => FRAGMENT_MERGEMODE_MORPH 
		} 
	);
	return @events;
}

sub execute_script {
	my ($writer, $signals) = @_;
	my $action = $signals->{script}{action};
	return unless $action;
	my $script = sprintf 'console.log("%s")', "Unknown script action $action";
	if ($action eq 'alert') {
		$script = sprintf 'window.alert("%s")', "the server says hello!";
	} elsif ($action eq 'reload') {
		$script = 'location.reload()'
	}
	my @events;
	push @events, Datastar::SSE->execute_script( $script );
	return @events;
}



$app;

