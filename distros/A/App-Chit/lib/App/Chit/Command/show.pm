use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::show;

use App::Chit -command;

use App::Chit::Util ();
use Term::ANSIColor qw( colored );

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Show recent chat history."
}

sub opt_spec {
	return (
		[ "msg|n=i",   "number of messages (default 20)" ],
		[ "colour|c",  "force colour" ],
		[ "nocolour",  "avoid colour" ],
	);
}

sub validate_args ( $self, $opt, $args ) {
	$opt->{msg} //= 20;
	$self->usage_error( "expected a positive number" )
		unless $opt->{msg} > 0;
	
	$opt->{colour} //= ( -t STDOUT );
	delete $opt->{colour} if $opt->{nocolour} || $ENV{NO_COLOR};
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	my $chit = App::Chit::Util::load_chit( $dir );
	
	my @log = @{ $chit->{chat} or [] };
	shift( @log ) while @log > $opt->{msg};
	
	for my $x ( @log ) {
		if ( $x->{role} eq 'user' ) {
			if ( $opt->{colour} ) {
				print colored( ['bold cyan'], $x->{content} ), "\n";
			}
			else {
				print "PROMPT: ", $x->{content}, "\n";
			}
		}
		else {
			if ( $opt->{colour} ) {
				print colored( ['white'], $x->{content} ), "\n";
			}
			else {
				print "RESPONSE: ", $x->{content}, "\n";
			}
			print "\n";
		}
	}
}

1;
