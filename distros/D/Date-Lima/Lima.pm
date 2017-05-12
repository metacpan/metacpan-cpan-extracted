package Date::Lima;

use strict;
no warnings;
use base 'Exporter';
use Carp;

our %EXPORT_TAGS = ( 'all' => [ qw(beek_date default_conversions nomonth_conversions weeklargest_conversions daysmallest_conversions interval2seconds rev) ] ); 
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT;
our $VERSION = '1.4300';

our @conversions;

# sidereal_conversions() {{{
sub sidereal_conversions() {
    my $sidereal_year  = 365.256_363_051 * 24 * 60 * 60;
    my $sidereal_month = $sidereal_year / 12;

    @conversions = (
        [  y => $sidereal_year  ],
        [ mo => $sidereal_month ],

        [  w => 7*24*60*60 ],
        [  d =>   24*60*60 ],
        [  h =>      60*60 ],
        [  m =>         60 ],
    );

    return;
}
# }}}
# daysmallest_conversions() {{{
sub daysmallest_conversions() {
    @conversions = (
        [  y => 365*24*60*60 ],
        [ mo =>  30*24*60*60 ],
        [  w =>   7*24*60*60 ],
        [  d =>     24*60*60 ],
    );

    return;
}
# }}}
# default_conversions() {{{
sub default_conversions() {
    @conversions = (
        [  y => 365*24*60*60 ],
        [ mo =>  30*24*60*60 ],
        [  w =>   7*24*60*60 ],
        [  d =>     24*60*60 ],
        [  h =>        60*60 ],
        [  m =>           60 ],
        [  s =>            1 ],
    );

    return;
}
# }}}
# nomonth_conversions() {{{
sub nomonth_conversions() {
    @conversions = (
        [  y => 365*24*60*60 ],
        [  w =>   7*24*60*60 ],
        [  d =>     24*60*60 ],
        [  h =>        60*60 ],
        [  m =>           60 ],
        [  s =>            1 ],
    );

    return;
}
# }}}
# weeklargest_conversions() {{{
sub weeklargest_conversions() {
    @conversions = (
        [  w => 7*24*60*60 ],
        [  d =>   24*60*60 ],
        [  h =>      60*60 ],
        [  m =>         60 ],
        [  s =>          1 ],
    );

    return;
}
# }}}

default_conversions();

# _to_secs {{{
sub _to_secs {
    my $time = shift;

    my ($H,$M,$S);

    if ( ($H, $M, $S) = $time =~ m/^(\d+):(\d{2}):(\d{2})$/ ) {
        return  $S
              + $M * 60
              + $H * 60 * 60;

    } elsif ( ($M, $S) = $time =~ m/^(\d+):(\d{2})$/ ) {
        return $S + $M * 60;

    } elsif( $time =~ m/^\d+$/ ) {
        return $time;
    }

    croak "time format not understood";
}
# }}}
# beek_date($) {{{
sub beek_date($) {
    my $s = shift;

    if ( $s =~ m/:/ ) {
        $s = eval { _to_secs($s) };

        croak $@ if $@;
    }

    my @res = map {
        my @r;

        if( my $v = int( $s / $_->[1] ) ) {
            $s -= $v * $_->[1];
            @r = "$v$_->[0]";
        }

    @r } @conversions;

    local $" = "";
    return @res ? "@res" : "0s";
}
# }}}
# {{{ sub rev($)
sub rev($) {
    my $td = shift;

    my %conversions = map {(@$_)} @conversions;
    my $conversions = do { local $" = "|"; my @c = keys %conversions; qr/(?:@c)/ };

    croak "interval format not understood" unless $td =~ m/^(?:\d+$conversions)*$/;
    my $s = 0;

    while( $td =~ m/(\d+)($conversions)/g ) {
        $s += $1 * $conversions{$2};
    }

    return $s;
}

*interval2seconds = \&rev;

# }}}

1;
