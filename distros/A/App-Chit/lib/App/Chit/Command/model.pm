use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::model;

use App::Chit -command;

use App::Chit::Util ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Show or set the ChatGPT language model."
}

sub opt_spec {
	return (
		[ "set=s",      "set model (see https://platform.openai.com/docs/models)" ],
	);
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	my $chit = App::Chit::Util::load_chit( $dir );
	
	if ( $opt->{set} ) {
		say "Previous model:   ", $chit->{model};
		say "Setting model to: ", $opt->{set};
		$chit->{model} = $opt->{set};
	}
	else {
		say $chit->{model};
	}
	
	App::Chit::Util::save_chit( $dir, $chit );
}

1;
