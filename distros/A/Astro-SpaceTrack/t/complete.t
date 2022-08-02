package main;

use 5.006002;

use strict;
use warnings;

BEGIN {
    delete $ENV{TZ};
}

use Astro::SpaceTrack;
use Test::More 0.88;	# Because of done_testing();

my $app = Astro::SpaceTrack->new();

{
    local $@ = undef;
    eval {
	$app->_get_readline();	# To initialize internals.
	1;
    } or plan skip_all => "Term::ReadLine not available: $@";
}

$INC{'Term/ReadLine/Perl.pm'}
    or plan skip_all => 'Term::ReadLine::Perl not available';

complete( '', get_builtins() );

complete( 'a', [ qw{ amsat attribute_names } ] );

complete( 'am', [ qw{ amsat } ] );

complete( 'amsat -', [ qw{ --file } ] );

complete( 'box_score -', [ qw{ --format --json --no-json } ] );

complete( 'box_score -n', [ qw{ --no-json } ] );

$app->set( direct => 1 );
complete( 'celestrak -',
    [ classic_retrieve_options() ],
    q/Complete 'celestrak -', direct => 1/,
);

$app->set( direct => 0 );
complete( 'celestrak -',
    [
	retrieve_options( [
		'observing_list|observing-list!' => 'return observing list',
	    ]
	)
    ],
    q/Complete 'celestrak -', direct => 0/,
);

complete( 'celestrak o', [ qw{ oneweb orbcomm other other-comm } ] );

complete( 'celestrak_supplemental -', [ qw{ --file --match --no-match
	--no-rms --rms } ] );

complete( 'celestrak_supplemental o', [ qw{ oneweb orbcomm } ] );

complete( 'favorite -', [ qw{ --format --json --no-json } ] );

complete( 'file -', [ retrieve_options() ] );

complete( 'get p', [ qw{ password pretty prompt } ] );

complete( 'iridium_status -', [ qw{ --no-raw --raw } ] );

complete( 'iridium_status s', [ qw{ sladen spacetrack } ] );

complete( 'launch_sites -', [ qw{ --format --json --no-json } ] );

complete( 'mccants -', [ qw{ --file } ] );

complete( 'mccants c', [ qw{ classified } ] );

complete( 'retrieve -', [ retrieve_options() ] );

complete( 'set p', [ qw{ password pretty prompt } ] );

complete( 'set password ', [] );

complete( 'show p', [ qw{ password pretty prompt } ] );

complete( 'spaceflight -', [ classic_retrieve_options( [
		'all!' => 'retrieve all data',
		'effective!' => 'include effective date',
	    ] ) ] );

complete( 'spacetrack -', [ qw{ --format --json --no-json } ] );

complete( 'spacetrack i', [ qw{ inmarsat intelsat iridium } ] );

complete( 'update -', [ retrieve_options() ] );

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
    goto &is_deeply;
}

{
    my @core;

    # If $add_core is true, you get 'core.' prefixed to the names of all
    # built-ins. If it is false, there is no prefix, but 'core.' is
    # added to the returned data.
    sub get_builtins {
	# my ( $add_core, @extra ) = @_;
	unless ( @core ) {
	    push @core, qw{ bye exit show };
	    foreach ( keys %Astro::SpaceTrack:: ) {
		m/ \A _ /smx
		    and next;
		m/ [[:upper:]] /smx
		    and next;
		my $code = Astro::SpaceTrack->can( $_ )
		    or next;
		{
		    can		=> 1,
		    getv	=> 1,
		    import	=> 1,
		    isa	=> 1,
		    new	=> 1,
		    spaceflight	=> 1,
		}->{$_}
		    and next;
		push @core, $_;
	    }
	    @core = sort @core;
	}
	return \@core;
    }
}

{
    my @opt;
    sub classic_retrieve_options {
	my ( $extra ) = @_;
	@opt
	    or @opt = sort +process_options(
		Astro::SpaceTrack::CLASSIC_RETRIEVE_OPTIONS() );
	$extra
	    and @{ $extra }
	    or return @opt;
	return sort @opt, process_options( $extra );
    }
}

{
    my @opt;
    sub retrieve_options {
	my ( $extra ) = @_;
	@opt
	    or @opt = sort +classic_retrieve_options( [
		'since_file=i'
		    => '(Return only results added after the given file number)',
		'json!'	=> '(Return TLEs in JSON format)',
		'format=s' => 'Specify data format'
	    ]
	);
	$extra
	    and @{ $extra }
	    or return @opt;
	return sort @opt, process_options( $extra );
    }
}

sub process_options {
    my ( $opt ) = @_;
    my %h = @{ $opt };
    my @o;
    foreach ( keys %h ) {
	my $type = '';
	s/ ( [!=:] ) .* //smx
	    and $type = $1;
	my @n = split qr< \| >smx;
	push @o, "--$_" for @n;
	$type eq q<!>
	    and push @o, "--no-$_" for @n;
    }
    return @o;
}

1;

# ex: set filetype=perl textwidth=72 :
