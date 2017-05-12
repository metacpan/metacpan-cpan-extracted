package main;

use strict;
use warnings;

use Astro::SpaceTrack;
use HTML::TreeBuilder;
use LWP::UserAgent;
use Test::More 0.96;

my $ua = LWP::UserAgent->new ();

# Redistributed TLEs

note 'Celestrak current data';

my $rslt = $ua->get ('http://celestrak.com/NORAD/elements/');

$rslt->is_success()
    or plan skip_all => 'Celestrak inaccessable: ' . $rslt->status_line;

my %got = parse_string( $rslt->content(), source => 'celestrak' );

my $st = Astro::SpaceTrack->new (direct => 1);

(undef, my $names) = $st->names ('celestrak');
my %expect;
foreach (@$names) {
    $expect{$_->[1]} = {
	name => $_->[0],
	ignore => 0,
    };
}

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
$expect{'2012-044'} = {
    name => 'BREEZE-M R/B Breakup (2012-044C)',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};

=begin comment

# Removed October 23, 2008

$expect{'usa-193-debris'} = {
    name => 'USA 193 Debris',
    note => 'Not actually provided as a fetchable data set.',
    ignore => 1,
};

=end comment

=cut

if ($expect{sts}) {
    $expect{sts}{note} = 'Only available when a mission is in progress.';
    $expect{sts}{ignore} = 1;	# What it says.
}

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

ok ( !%got, 'The above is all there is' ) or do {
    diag( 'The following have been added:' );
    foreach (sort keys %got) {
	diag( "    $_ => '$got{$_}{name}'" );
    }
};

# Supplemental TLEs

note 'Celestrak supplemental data';

$rslt = $ua->get ('http://celestrak.com/NORAD/elements/supplemental/');

%got = parse_string( $rslt->content, source => 'celestrak_supplemental' );

foreach my $key ( keys %got ) {
    $key !~ m{ / }smx
	and $key !~ m{ [.] rms \z }smx
	and next;
    delete $got{$key};
}

( undef, $names ) = $st->names( 'celestrak_supplemental' );

%expect = ();

foreach ( @{ $names } ) {
    $expect{$_->[1]} = {
	name => $_->[0],
	ignore => 0,
    };
}

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

ok ( !%got, 'The above is all there is' ) or do {
    diag( 'The following have been added:' );
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
	$href =~ s/ [.] txt \z //smx
	    or next;
	$href =~ m{ / }smx
	    and next;
	$data{$href} = {
	    name	=> $anchor->as_trimmed_text(),
	    @extra,
	};

    }
    return %data;
}

1;

# ex: set textwidth=72 :
