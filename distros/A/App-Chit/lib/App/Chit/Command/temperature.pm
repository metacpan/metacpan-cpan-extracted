use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::temperature;

use App::Chit -command;

use App::Chit::Util ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Show or set the temperature for this chat."
}

sub opt_spec {
	return (
		[ "set=f",      "set temperature (decimal number from 0.0 to 2.0)" ],
	);
}

sub validate_args ( $self, $opt, $args ) {
	if ( exists $opt->{set} ) {
		$self->usage_error( "too hot" ) if $opt->{set} > 2;
		$self->usage_error( "too cold" ) if $opt->{set} < 0;
	}
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	my $chit = App::Chit::Util::load_chit( $dir );
	
	if ( $opt->{set} ) {
		say "Previous temperature:   ", sprintf( '%.03f', $chit->{temperature} );
		say "Setting temperature to: ", $opt->{set};
		$chit->{temperature} = $opt->{set};
	}
	else {
		say sprintf( '%.03f', $chit->{temperature} );
	}
	
	App::Chit::Util::save_chit( $dir, $chit );
}

1;
