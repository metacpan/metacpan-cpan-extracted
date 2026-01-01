use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::role;

use App::Chit -command;

use App::Chit::Util ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Show or set ChatGPT's role in the chat."
}

sub opt_spec {
	return (
		[ "set=s",      "set role" ],
	);
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	my $chit = App::Chit::Util::load_chit( $dir );
	
	if ( $opt->{set} ) {
		say "Previous role:   ", $chit->{role};
		say "Setting role to: ", $opt->{set};
		$chit->{role} = $opt->{set};
	}
	else {
		say $chit->{role};
	}
	
	App::Chit::Util::save_chit( $dir, $chit );
}

1;
