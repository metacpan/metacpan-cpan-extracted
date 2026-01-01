use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::chat;

use App::Chit -command;

use App::Chit::Util ();
use Carp qw( croak );
use Path::Tiny qw( path );
use Term::Spinner::Color ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Chat with ChatGPT."
}

sub opt_spec {
	return (
		[ "temperature=f", "temperature for response" ],
		[ "stdin",         "prompt from STDIN" ],
		[ "file=s",        "prompt from file" ],
	);
}

sub validate_args ( $self, $opt, $args ) {
	unless ( $opt->{stdin} or $opt->{file} ) {
		$self->usage_error( "expected a prompt on the command line, or -i, or -f" )
			unless ( @$args == 1 and length($args->[0]) > 2 );
	}
	
	$self->usage_error( "cannot use both -i and -f" )
		if ( $opt->{stdin} and $opt->{file} );
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	my $chit = App::Chit::Util::load_chit( $dir );
	
	my $spin;
	$spin = Term::Spinner::Color->new(
		'delay' => 0.3,
		'colorcycle' => 1,
	) if -t STDOUT;
	
	$spin->auto_start if $spin;
	
	my $prompt = do {
		if ( $opt->{stdin} ) {
			local $/;
			<STDIN>;
		}
		elsif ( $opt->{file} ) {
			my $f = path( $opt->{file} );
			$f->is_file or croak("File does not exist");
			$f->slurp_utf8;
		}
		else {
			$args->[0];
		}
	};
	chomp $prompt;
	
	my @log = @{ $chit->{chat} or [] };
	unshift @log, { role => 'system', content => $chit->{role} };
	push @log, { role => 'user', content => $prompt };
	
	my $temperature = $opt->{temperature} // $chit->{temperature};
	
	my $gpt = App::Chit::Util::chatgpt( $chit );
	my $response = $gpt->chat( \@log, $temperature );
	$spin->auto_done if $spin;
	if ( defined $response ) {
		chomp $response;
		say $response;
		push @{ $chit->{chat} //= [] },
			{ role => 'user',      content => $prompt },
			{ role => 'assistant', content => $response };
	}
	else {
		croak( "Error: " . $gpt->error );
	}
	
	App::Chit::Util::save_chit( $dir, $chit );
}

1;
