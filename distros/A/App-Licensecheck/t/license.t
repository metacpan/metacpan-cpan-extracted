use strictures 2;

use Test::Roo tests => 22;
use App::Licensecheck;

has encoding => ( is => 'ro' );
has license  => ( is => 'ro', required => 1 );
has corpus   => ( is => 'ro' );

sub _build_description { return shift->license }

test "Parse corpus" => sub {
	my $self = shift;

	my $app = App::Licensecheck->new;
	$app->lines(0);
	$app->deb_fmt(1);
	$app->encoding( $self->encoding ) if $self->encoding;

	foreach (
		ref( $self->corpus ) eq 'ARRAY' ? @{ $self->corpus } : $self->corpus )
	{
		my ( $license, $copyright ) = $app->parse("t/devscripts/$_");
		is( $license, $self->license, "Corpus file $_" );
	}
};

run_me( { license => 'AFL-3.0', corpus => 'academic.h' } );
run_me(
	{ license => 'Apache-2.0', corpus => '../grant/Apache/one_helper.rb' } );
run_me(
	{   license => 'Artistic-2.0',
		corpus  => [qw(artistic-2-0-modules.pm artistic-2-0.txt)]
	}
);
run_me( { license => 'Beerware',        corpus => 'beerware.cpp' } );
run_me( { license => 'BSD~unspecified', corpus => 'bsd-1-clause-1.c' } );
run_me( { license => 'BSD-2-clause',    corpus => 'bsd.f' } );
run_me(
	{   license => 'BSD-3-clause',
		corpus  => [
			qw(bsd-3-clause.cpp bsd-3-clause-authorsany.c mame-style.c bsd-regents.c)
		]
	}
);
run_me( { license => 'BSL',     corpus => 'boost.h' } );
run_me( { license => 'EPL-1.0', corpus => 'epl.h' } );

# Lisp Lesser General Public License (BTS #806424)
# see http://opensource.franz.com/preamble.html
run_me( { license => 'LLGPL',  corpus => 'llgpl.lisp' } );
run_me( { license => 'GPL',    corpus => 'gpl-no-version.h' } );
run_me( { license => 'GPL-1+', corpus => 'gpl-1' } );
run_me(
	{   license => 'GPL-2',
		corpus  => [
			qw(gpl-2 bug-559429 gpl-2-comma.sh gpl-2-incorrect-address copr-iso8859.h)
		]
	}
);
run_me(
	{ license => 'GPL-2+', corpus => [qw(gpl-2+ gpl-2+.scm copr-utf8.h)] } );
run_me( { license => 'GPL-3', corpus => [qw(gpl-3.sh gpl-3-only.c)] } );
run_me(
	{   license => 'GPL-3+',
		corpus  => [
			qw(gpl-3+ gpl-3+-with-rem-comment.xml gpl-variation.c gpl-3+.el comments-detection.h)
		]
	}
);
run_me( { license => 'MPL-1.1', corpus => 'mpl-1.1.sh' } );
run_me(
	{ license => 'MPL-2.0', corpus => [qw(mpl-2.0.sh mpl-2.0-comma.sh)] } );
run_me( { license => 'FTL',   corpus => 'freetype.c' } );
run_me( { license => 'CDDL',  corpus => 'cddl.h' } );
run_me( { license => 'ISC',   corpus => 'libuv-isc.am' } );
run_me( { license => 'Expat', corpus => 'info-at-eof.h' } );
