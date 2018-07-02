package My::Module::Test;

use 5.006002;

use strict;
use warnings;

our $VERSION = '0.099';

use Exporter qw{ import };

use Astro::Coord::ECI::TLE qw{ :constants };
use Astro::Coord::ECI::Utils qw{ rad2deg };
use Test::More 0.88;

use constant CODE_REF	=> ref sub {};

our @EXPORT_OK = qw{
    format_pass format_time
    magnitude
    tolerance tolerance_frac
    velocity_sanity
};
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    format => [ qw{ format_pass format_time } ],
    tolerance => [ qw{ tolerance tolerance_frac } ],
);

# Perl::Critic can't find interpolated sub calls
sub _dor {	## no critic (ProhibitUnusedPrivateSubroutines)
    foreach ( @_ ) {
	defined $_ and return $_;
    }
    return;
}

{

    my @decoder;

    # We jump through this hoop in case the constants turn out not to be
    # dualvars.
    BEGIN {
	$decoder[ PASS_EVENT_NONE ]	= '';
	$decoder[ PASS_EVENT_SHADOWED ]	= 'shdw';
	$decoder[ PASS_EVENT_LIT ]	= 'lit';
	$decoder[ PASS_EVENT_DAY ]	= 'day';
	$decoder[ PASS_EVENT_RISE ]	= 'rise';
	$decoder[ PASS_EVENT_MAX ]	= 'max';
	$decoder[ PASS_EVENT_SET ]	= 'set';
	$decoder[ PASS_EVENT_APPULSE ]	= 'apls';
	$decoder[ PASS_EVENT_START ]	= 'start';
	$decoder[ PASS_EVENT_END ]	= 'end';
    }

    sub _format_event {
	my ( $event ) = @_;
	defined $event or return '';
	return $decoder[ $event + 0 ];
    }

}

sub format_pass {
    my @passes = @_;
    my $rslt = '';
    foreach my $pass ( @passes ) {
	$pass
	    or next;
	$rslt .= "\n";
	foreach my $event ( @{ $pass->{events} } ) {
	    $rslt .= sprintf '%19s %5s %5s %7s %-5s %-5s',
		format_time( $event->{time} ),
		_format_optional( '%5.1f', $event, 'elevation', \&rad2deg ),
		_format_optional( '%5.1f', $event, 'azimuth', \&rad2deg ),
		_format_optional( '%7.1f', $event, 'range' ),
		_format_event( $event->{illumination} ),
		_format_event( $event->{event} ),
		;
	    $rslt =~ s/ \s+ \z //smx;
	    $rslt .= "\n";
	    if ( $event->{appulse} ) {
		my $sta = $event->{station};
		my ( $az, $el ) = $sta->azel(
		    $event->{appulse}{body}->universal( $event->{time} ) );
		$rslt .= sprintf '%19s %5.1f %5.1f %7.1f %s', '',
		    rad2deg( $el ),
		    rad2deg( $az ),
		    rad2deg( $event->{appulse}{angle} ),
		    $event->{appulse}{body}->get( 'name' ),
		    ;
		$rslt =~ s/ \s+ \z //smx;
		$rslt .= "\n";
	    }
	}
    }
    $rslt =~ s/ \A \n //smx;
    $rslt =~ s/ (?<= \s ) - (?= 0 [.] 0+ \s ) / /smxg;
    return $rslt;
}

sub _format_optional {
    my ( $tplt, $hash, $key, $xfrm ) = @_;
    defined( my $val = $hash->{$key} )
	or return '';
    CODE_REF eq ref $xfrm
	and $val = $xfrm->( $val );
    return sprintf $tplt, $val;
}

sub format_time {
    my ( $time ) = @_;
    my @parts = gmtime int( $time + 0.5 );
    return sprintf '%04d/%02d/%02d %02d:%02d:%02d', $parts[5] + 1900,
	$parts[4] + 1, @parts[ 3, 2, 1, 0 ];
}

sub magnitude (@) {
    my ( $tle, @arg ) = @_;
    my ( $time, $want, $name ) = splice @arg, -3;
    my $got;
    eval {
	$got = $tle->universal( $time )->magnitude( @arg );
	defined $got
	    and $got = sprintf '%.1f', $got;
	1;
    } or do {
	@_ = "$name failed: $@";
	goto &fail;
    };
    if ( defined $want ) {
	$want = sprintf '%.1f', $want;
	@_ = ( $got, 'eq', $want, $name );
	goto &cmp_ok;
    } else {
	@_ = ( ! defined $got, $name );
	goto &ok;
    }
}

sub tolerance (@) {
    my ( $got, $want, $tolerance, $title, $fmtr ) = @_;
    $fmtr ||= sub { return $_[0] };
    $title =~ s{ (?<! [.] ) \z }{.}smx;
    my $delta = $got - $want;
    my $rslt = abs( $delta ) < $tolerance;
    $rslt or $title .= <<"EOD";

         Got: @{[ $fmtr->( $got ) ]}
    Expected: @{[ $fmtr->( $want ) ]}
  Difference: $delta
   Tolerance: $tolerance
EOD
    chomp $title;
    @_ = ( $rslt, $title );
    goto &ok;
}

sub tolerance_frac (@) {
    my ( $got, $want, $tolerance, $title, $fmtr ) = @_;
    @_ = ( $got, $want, $tolerance * abs $want, $title, $fmtr );
    goto &tolerance;
}

{
    my @dim_name = qw{ X Y Z };
    my %method_dim_name = (
	azel	=> [ qw{ azimuth elevation range } ],
	equatorial => [ 'right ascension', 'declination', 'range' ],
    );
    my %tweak = (
	azel => sub {
	    my ( $delta, $current, $previous ) = @_;
	    $delta->[0] *= cos( ( $current->[1] + $previous->[1] ) / 2 );
	    return;
	},
	equatorial => sub {
	    my ( $delta, $current, $previous ) = @_;
	    $delta->[1] *= cos( ( $current->[0] + $previous->[0] ) / 2 );
	    return;
	},
    );

    sub velocity_sanity ($$;$) {
	my ( $method, $body, $sta ) = @_;
	my $time = $body->universal();
	my @rslt;
	foreach my $delta_t ( 0, 1 ) {
	    $delta_t
		and $body->universal( $time + $delta_t );
	    my @coord = $sta ? $sta->$method( $body ) :
		$body->$method();
	    # Accommodate internal methods that return a reference to an
	    # array of intermediate results.
	    ref @coord and shift @coord;
	    push @rslt, \@coord;
	}
	my @delta_p = map { $rslt[1][$_] - $rslt[0][$_] } ( 0 .. 2 );
	$tweak{$method}
	    and $tweak{$method}->( \@delta_p, @rslt );
	my @time_a = gmtime $time;
	my $title = sprintf
	    '%s converted to %s at %i/%i/%i %i:%02i:%02i GMT',
	    $body->get( 'name' ) || $body->get( 'id' ), $method,
	    $time_a[5] + 1900, $time_a[4] + 1, @time_a[ 3, 2, 1, 0 ];
	my $grade = \&pass;
	foreach my $inx ( 0 .. 2 ) {
	    my $v_inx = $inx + 3;
	    defined $rslt[0][$v_inx]
		and defined $rslt[1][$v_inx]
		and $rslt[0][$v_inx] <= $delta_p[$inx]
		and $delta_p[$inx] <= $rslt[1][$v_inx]
		and next;
	    defined $rslt[0][$v_inx]
		and defined $rslt[1][$v_inx]
		and $rslt[0][$v_inx] >= $delta_p[$inx]
		and $delta_p[$inx] >= $rslt[1][$v_inx]
		and next;
	    my $dim = $method_dim_name{$method}[$inx] || $dim_name[$inx];
	    $grade = \&fail;
	    $title .= <<"EOD";


           $dim( t + 1 ): $rslt[1][$inx]
               $dim( t ): $rslt[0][$inx]
          $dim dot ( t ): @{[ _dor( $rslt[0][$v_inx], '<undef>' ) ]}
  $dim( t + 1 ) - $dim( t ): $delta_p[$inx]
      $dim dot ( t + 1 ): @{[ _dor( $rslt[1][$v_inx], '<undef>' ) ]}
EOD
	    chomp $title;
	}
	@_ = ( $title );
	goto &$grade;
    }
}

1;

__END__

=head1 NAME

My::Module::Test - Useful subroutines for testing

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test qw{ :all };
 
 say 'Time: ', format_time( time );

=head1 DESCRIPTION

This module is private to the My::Module package. The author
reserves the right to change or revoke it without notice.

This module is a repository for subroutines used in testing
L<My::Module|My::Module>.


=head1 SUBROUTINES

The following public subroutines are exported by this module. None of
them are exported by default, but export tag C<:all> exports all of
them.

=head2 format_pass

 print format_pass( $pass, ... );

This subroutine converts the given C<$pass>es (which are references to
the hashes returned by the C<My::Module::TLE> C<pass()>
method) to a string. The output contains the events of the passes one
per line, with date and time (ISO-8601-ish, GMT), azimuth, elevation and
range (or blanks if not present), illumination, and event name for each
pass.  For appulses the time, position, and name of the appulsed body
are also provided, on a line after the event.

=head2 format_time

 print format_time( $pass->{time} );

This subroutine converts a given Perl time into an ISO-8601-ish GMT
time. It is used by C<format_pass()>.

=head2 tolerance

 tolerance $got, $want, $tolerance, $title, $formatter

This subroutine runs a test, to see if the absolute value of
C<$got - $want> is less than C<$tolerance>. If so, the test passes. If
not, it fails. This subroutine computes the passage or failure, but does
a C<< goto &Test::More::ok >> to generate the appropriate TAP output.
However, if the test is going to fail, the title is modified to include
the C<$got> and C<$want> values, their difference, and the tolerance.

The C<$formatter> argument is optional. If specified, it is a reference
to code used to format the C<$got> and C<$want> values for display if
the test fails. The formatter will be called with a single argument,
which is the value to display.

This subroutine is prototyped C<(@)>.

=head2 tolerance_frac

 tolerance_frac $got, $want, $tolerance, $title

This subroutine is a variant on C<tolerance()> in which the tolerance is
expressed as a fraction of the C<$want> value. It is actually just a
stub that replaces the C<$tolerance> argument by
C<< abs( $want * $tolerance ) >> and then does a C<goto &tolerance>.

This subroutine is prototyped C<(@)>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
