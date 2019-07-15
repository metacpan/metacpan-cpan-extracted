package App::MonM::Util; # $Id: Util.pm 85 2019-07-14 12:03:14Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Util - Internal utilities

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Util qw/
            explain expire_calc
        /;

    print explain( $object );

=head1 DESCRIPTION

Internal utilities

=head1 FUNCTIONS

=over 4

=item B<explain>

    print explain( $object );

Returns Data::Dumper dump

=item B<blue>, B<cyan>, B<green>, B<red>, B<yellow>

    print cyan("Format %s", "text");

Returns colored string

=item B<getExpireOffset>

    print getExpireOffset("+1d"); # 86400
    print getExpireOffset("-1d"); # -86400

Returns offset of expires time (in secs).

Original this function is the part of CGI::Util::expire_calc!

This internal routine creates an expires time exactly some number of hours from the current time.
It incorporates modifications from  Mark Fisher.

format for time can be in any of the forms:

    now   -- expire immediately
    +180s -- in 180 seconds
    +2m   -- in 2 minutes
    +12h  -- in 12 hours
    +1d   -- in 1 day
    +3M   -- in 3 months
    +2y   -- in 2 years
    -3m   -- 3 minutes ago(!)

If you don't supply one of these forms, we assume you are specifying the date yourself

=item B<getBit>

    print getBit(123, 3) ? "SET" : "UNSET"; # UNSET

Getting specified Bit

=item B<node2anode>

    my $anode = node2anode({});

Returns array of nodes

=item B<set2attr>

    my $hash = set2attr({set => ["AttrName Value"]}); # {"AttrName" => "Value"}

Converts attributes from the "set" format to regular hash

=item B<setBit>

    printf("%08b", setBit(123, 3)); # 01111111

Setting specified Bit. Returns new value.

=back

=head1 HISTORY

See C<Changes> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT @EXPORT_OK /;
$VERSION = '1.01';

use Data::Dumper; #$Data::Dumper::Deparse = 1;
use Term::ANSIColor qw/ colored /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util qw/ trim /;

use constant {
        BIT_SET     => 1,
        BIT_UNSET   => 0,
    };

use base qw/Exporter/;
@EXPORT = qw/
        blue green red yellow cyan
    /;
@EXPORT_OK = qw/
        explain
        getExpireOffset
        node2anode set2attr
        getBit setBit
    /;

sub explain {
    my $dumper = new Data::Dumper( [shift] );
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}
sub getExpireOffset {
    my $time = trim(shift // 0);
    my %mult = (
            's' => 1,
            'm' => 60,
            'h' => 60*60,
            'd' => 60*60*24,
            'M' => 60*60*24*30,
            'y' => 60*60*24*365
        );
    if (!$time || (lc($time) eq 'now')) {
        return 0;
    } elsif ($time =~ /^\d+$/) {
        return $time; # secs
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
        return ($mult{$2} || 1) * $1;
    }
    return $time;
}

sub node2anode {
    my $n = shift;
    return [] unless $n && ref($n) =~ /ARRAY|HASH/;
    return [$n] if ref($n) eq 'HASH';
    return $n;
}
sub set2attr {
    my $in = shift;
    my $attr = is_array($in) ? $in : array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    return {%attrs};
}
sub setBit {
    my $v = fv2zero(shift);
    my $n = fv2zero(shift);
    return $v | (2**$n);
}
sub getBit {
    my $v = fv2zero(shift);
    my $n = fv2zero(shift);
    return ($v & (1 << $n)) ? BIT_SET : BIT_UNSET;
}

# Colored helper functions
sub green {  colored(['bright_green'],  sprintf(shift, @_)) }
sub red {    colored(['bright_red'],    sprintf(shift, @_)) }
sub yellow { colored(['bright_yellow'], sprintf(shift, @_)) }
sub cyan {   colored(['bright_cyan'],   sprintf(shift, @_)) }
sub blue {   colored(['bright_blue'],   sprintf(shift, @_)) }

1;

__END__
