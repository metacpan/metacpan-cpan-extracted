package main;

use strict;
use warnings;

use Astro::SpaceTrack;
use HTML::TreeBuilder;
use LWP::UserAgent;
use Test::More 0.96;
use URI;

my $ua = LWP::UserAgent->new ();

# Redistributed TLEs

note 'Celestrak current data';

my $rslt = $ua->get ('https://celestrak.org/NORAD/elements/');

$rslt->is_success()
    or plan skip_all => 'Celestrak inaccessable: ' . $rslt->status_line;

my %got = parse_string( $rslt->content(), source => 'celestrak' );

my $st = Astro::SpaceTrack->new();

my %expect = %{ $st->__catalog( 'celestrak' ) };

=begin comment

# Fetchable as of November 16 2021.

$expect{'1999-025'} = {
    name => 'Fengyun 1C debris',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};
$expect{'cosmos-2251-debris'} = {
    name => 'Cosmos 2251 debris',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};
$expect{'iridium-33-debris'} = {
    name => 'Iridium 33 debris',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};
$expect{'2019-006'} = {
    name	=> 'Indian ASAT Test Debris',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};

# Removed October 23, 2008
$expect{'usa-193-debris'} = {
    name => 'USA 193 Debris',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};

# Keys relocated to Astro::SpaceTrack April 26 2024.
$expect{'2012-044'} = {
    name => 'BREEZE-M R/B Breakup (2012-044C)',
    note => 'Fetchable as of November 16 2021, but not on web page',
    ignore => 1,
};

# Removed April 26 2024
if ($expect{sts}) {
    $expect{sts}{note} = 'Only available when a mission is in progress.';
    $expect{sts}{ignore} = 1;	# What it says.
}

=end comment

=cut

foreach my $key (sort keys %expect) {
    if ($expect{$key}{ignore}) {
	my $presence = delete $got{$key} ? 'present' : 'not present';
	note "Ignored - $key (@{[($got{$key} ||
		$expect{$key})->{name}]}): $presence";
	$expect{$key}{note} and note( "    $expect{$key}{note}" );
    } else {
	ok delete $got{$key}, $expect{$key}{name};
	$expect{$key}{note} and note "    $expect{$key}{note}";
    }
}

ok ( ! keys %got, 'The above is all there is' ) or do {
    diag( 'The following primary data sets have been added:' );
    foreach (sort keys %got) {
	diag( "    $_ => '$got{$_}{name}'" );
    }
};

# Supplemental TLEs

note 'Celestrak supplemental data';

$rslt = $ua->get ('https://celestrak.org/NORAD/elements/supplemental/');

%got = parse_string( $rslt->content, source => 'celestrak_supplemental' );

foreach my $key ( keys %got ) {
    $key !~ m{ / }smx
	and $key !~ m{ [.] rms \z }smx
	and $key !~ m{ [.] match \z }smx
	and next;
    delete $got{$key};
}

# diag 'Debug - got ', explain \%got;

%expect = %{ Astro::SpaceTrack->__catalog( 'celestrak_supplemental' ) };
%{ $_ } = ( %{ $_ }, ignore => 0 ) for values %expect;

foreach my $key ( keys %got ) {
    if ( $got{$key}{name} =~ m/ \b (
	pre-launch | post-deployment | backup \s+ launch \s+ opportunity
	) \b /smxi ) {
	$expect{$key}{note} = "\u$1 data sets are temporary";
	$expect{$key}{name} ||= $got{$key}{name};
	$expect{$key}{ignore} = 1;
    }
}

# diag 'Debug - want ', explain \%expect;

foreach my $key (sort keys %expect) {
    my $source = $expect{$key}{source} || $key;
    if ($expect{$key}{ignore}) {
	my $presence = delete $got{$source} ? 'present' : 'not present';
	note "Ignored - $key (@{[($got{$source} ||
		$expect{$key})->{name}]}): $presence";
	$expect{$key}{note} and note( "    $expect{$key}{note}" );
    } else {
	ok delete $got{$source}, $expect{$key}{name};
	$expect{$key}{note} and note "    $expect{$key}{note}";
    }
}

ok ( ! keys %got, 'The above is all there is' ) or do {
    diag( 'The following supplemental data sets have been added:' );
    foreach (sort keys %got) {
	diag( "    $got{$_}{source} $_ => '$got{$_}{name}'" );
    }
};

done_testing;

sub parse_string {
    my ( $string, @extra ) = @_;
    my $tree = HTML::TreeBuilder->new_from_content( $string );
    my %data;
    foreach my $anchor ( $tree->look_down( _tag => 'a' ) ) {
	my $href = $anchor->attr( 'href' )
	    or next;

	# Exclude pre-launch and post-deployment data sets, which are
	# ephemeral.
	my $parent = $anchor->parent();
	my @sibs = $parent->content_list();
	not ref $sibs[0]
	    and $sibs[0] =~ m/ \b (?:
		pre-launch | post-deployment |
		backup \s+ launch \s+ opportunity
		) \b /smxi
	    and next;

	if ( $href =~ m/ \b (?: sup- )? gp\.php \b /smx ) {
	    my $uri = URI->new( $href );
	    # NOTE convenient in this case but technically incorrect as
	    # it is legal for keys to repeat.
	    my %query = $uri->query_form();
	    #         Celestrak        Celestrak Supplemental
	    $href = ( $query{GROUP} || $query{FILE} )
		or next;
	} else {
	    $href =~ s/ [.] txt \z //smx
		or next;
	    $href =~ m{ / }smx
		and next;
	}
	my $name = $anchor->as_trimmed_text();
	$name eq ''
	    and not ref $sibs[0]
	    and $name = $sibs[0];
	$data{$href} = {
	    name	=> $name,
	    @extra,
	};

    }
    return %data;
}

1;

# ex: set textwidth=72 :
