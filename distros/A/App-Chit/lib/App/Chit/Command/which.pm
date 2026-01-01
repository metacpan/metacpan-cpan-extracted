use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Command::which;

use App::Chit -command;

use App::Chit::Util ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub abstract {
	return "Which directory is this chat associated with?"
}

sub opt_spec {
	return ();
}

sub execute ( $self, $opt, $args ) {
	my $dir = App::Chit::Util::find_chit_dir()
		or $self->usage_error("need to initialize chit first");
	print $dir->absolute->stringify, "\n";
}

1;
