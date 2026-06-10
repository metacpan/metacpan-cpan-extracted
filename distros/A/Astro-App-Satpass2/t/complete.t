package main;

use 5.008;

use strict;
use warnings;

BEGIN {
    delete $ENV{TZ};
}

use Astro::App::Satpass2;
use Test2::V0;

my $app = Astro::App::Satpass2->new();
{
    # We need to ensure Astro::App::Satpass2 thinks we're interactive to
    # get the initializatoin we need.
    my $mock = mock 'Astro::App::Satpass2' => (
	override	=> [
	    _get_interactive	=> sub { 1 },
	],
    );
    $app->_get_readline();	# To initialize internals.
}
$INC{'Term/ReadLine/Perl.pm'}
    or skip_all 'Term::ReadLine::Perl not available';


complete( '', get_builtins( 0 ) );

complete( 'core.', get_builtins( 1 ) );

$app->macro( define => hi => 'echo hello world' );
$app->macro( define => bye => 'echo goodbye cruel world' );
$app->macro( define => '--completion', 'mercury venus mars', planet =>
    'echo "\\L\\u$1"' );

complete( '', get_builtins( 0, qw{ bye hi planet } ),
    q<Complete '' after defining macros> );

complete( 'a', [ qw{ alias almanac } ] );

complete( 'core.a', [ qw{ core.alias core.almanac } ] );

complete( 'al', [ qw{ alias almanac } ] );

complete( 'alm', [ qw{ almanac } ] );

complete( 'z', [] );

complete( 'almanac -h', [ qw{ -horizon } ] );

complete( 'almanac --h', [ qw{ --horizon } ] );

complete( 'formatter ', [ qw{
	date_format
	desired_equinox_dynamical
	gmt
	local_coord
	template
	time_format
	tz
	} ] );

complete( 'formatter d', [ qw{
	date_format
	desired_equinox_dynamical
	} ] );

complete( 'formatter te', [ qw{
	template
	} ] );

complete( 'formatter template -', [ qw{
	-changes
	-raw
	} ] );

complete( 'formatter template lo', [ qw{
	location
	} ] );

complete( 'macro ', [ qw{ brief define delete list load } ] );

complete( 'core.macro ', [ qw{ brief define delete list load } ] );

complete( 'macro l', [ qw{ list load } ] );

complete( 'core.macro l', [ qw{ list load } ] );

complete( 'macro lo', [ qw{ load } ] );

complete( 'core.macro lo', [ qw{ load } ] );

complete( 'macro load -', [ qw{ -lib -verbose } ] );

complete( 'core.macro load -', [ qw{ -lib -verbose } ] );

complete( 'macro load --', [ qw{ --lib --verbose } ] );

complete( 'core.macro load --', [ qw{ --lib --verbose } ] );

complete( 'macro list ', [ qw{ bye hi planet } ] );

complete( 'macro list h', [ qw{ hi } ] );

complete( 'macro list z', [] );

complete( 'planet ', [ qw{ mars mercury venus } ] );

complete( 'planet m', [ qw{ mars mercury } ] );

complete( 'planet v', [ qw{ venus } ] );

complete( 'show i', [ qw{ illum initfile } ] );

complete( 'sky ', [ qw{ add class clear drop list load lookup tle } ] );

complete( 'sky l', [ qw{ list load lookup } ] );

complete( 'sky lo', [ qw{ load lookup } ] );

complete( 'sky loa', [ qw{ load } ] );

complete( 'sky class -', [ qw{ -add -delete } ] );

complete( 'sky class --', [ qw{ --add --delete } ] );

done_testing;

sub complete {
    my ( $line, $want, $name ) = @_;

    my $start = length $line;
    my $text;
    if ( $line =~ m/ ( \S+ ) \z /smx ) {
	$start -= length $1;
	$text = ( split qr< \s+ >smx, $line )[-1];
    } else {
	$text = '';
    }

    my @rslt = $app->__readline_completer( $text, $line, $start );

    @_ = ( \@rslt, $want, $name || "Complete '$line'" );
    goto &is;
}

{
    my @core;

    # If $add_core is true, you get 'core.' prefixed to the names of all
    # built-ins. If it is false, there is no prefix, but 'core.' is
    # added to the returned data.
    sub get_builtins {
	my ( $add_core, @extra ) = @_;
	unless ( @core ) {
	    foreach ( keys %Astro::App::Satpass2:: ) {
		m/ \A _ /smx
		    and next;
		my $code = Astro::App::Satpass2->can( $_ )
		    or next;
		Astro::App::Satpass2->__get_attr( $code, 'Verb' )
		    or next;
		push @core, $_;
	    }
	}
	my @rslt = $add_core ?
	    sort map { "core.$_" } @core, @extra :
	    sort @core, 'core.', @extra;
	return \@rslt;
    }
}

1;

# ex: set textwidth=72 :
