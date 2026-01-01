use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::maxhistory;

use App::Chit -command;

use App::Chit::Util ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Show or set the current maximum chat history length."
}

sub opt_spec {
	return (
		[ "set=i",      "set maximum chat history length" ],
	);
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	my $chit = App::Chit::Util::load_chit( $dir );
	
	if ( length $opt->{set} ) {
		say "Previous maximum history length:   ", int( 0 + $chit->{history} );
		say "Setting maximum history length to: ", $opt->{set};
		$chit->{history} = $opt->{set};
	}
	else {
		say int( 0 + $chit->{history} );
	}
	
	App::Chit::Util::save_chit( $dir, $chit );
}

1;
