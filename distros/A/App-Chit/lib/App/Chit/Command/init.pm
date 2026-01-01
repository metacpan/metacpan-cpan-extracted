use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::init;

use App::Chit -command;

use App::Chit::Util ();
use Cwd qw( getcwd );
use Path::Tiny qw( path );

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Initialize chit in the current working directory."
}

sub opt_spec {
	return (
		[ "clean|c",    "use a clean slate" ],
		[ "autofork|a", "fork existing chat from up level directory" ],
		[ "fork|f=s",   "fork existing chat from specified directory" ],
		[ "overwrite",  "overwrite current configuration" ],
	);
}

sub validate_args ( $self, $opt, $args ) {
	exists $opt->{clean}
		or exists $opt->{autofork}
		or exists $opt->{fork}
		or $self->usage_error( "need one of --clean, --autofork, or --fork" );
}

sub execute ( $self, $opt, $args ) {
	my $dir = path( getcwd );
	
	if ( App::Chit::Util::is_chit_dir( $dir ) ) {
		if ( $opt->{overwrite} ) {
			$dir->child( App::Chit::Util::CHIT_FILENAME )->remove;
		}
		else {
			$self->usage_error("already initialized, please use --overwrite");
		}
	}
	
	my $chit;
	if ( $opt->{clean} ) {
		$chit = {};
	}
	elsif ( $opt->{autofork} ) {
		$chit = App::Chit::Util::load_chit( App::Chit::Util::find_chit_dir() );
	}
	elsif ( $opt->{fork} ) {
		$chit = App::Chit::Util::load_chit( App::Chit::Util::find_chit_dir( $opt->{fork} ) );
	}
	App::Chit::Util::save_chit( $dir, $chit );
	
	say "ok";
}

1;
