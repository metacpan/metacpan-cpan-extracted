package Business::Shipping::Util;

=head1 NAME

Business::Shipping::Util - Miscellaneous functions

=head1 DESCRIPTION

Misc functions.

=head1 METHODS

=cut

use strict;
use warnings;
use base ('Exporter');
use Data::Dumper;
use Business::Shipping::Logging;
use Carp;
use File::Find;
use File::Copy;
use Fcntl ':flock';
use English;
use version; our $VERSION = qv('400');
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw( looks_like_number unique );

=head2 * currency( $opt, $amount )

Formats a number for display as currency in the current locale (currently, the
only locale supported is USD).

=cut

sub currency {
    my ($opt, $amount) = @_;

    return unless $amount;
    $amount = sprintf("%.2f", $amount);
    $amount = "\$$amount" unless $opt->{no_format};

    return $amount;
}

=head2 * unique( @ary )

Removes duplicates (but leaves at least one).

=cut

sub unique {
    my (@ary) = @_;

    my %seen;
    my @unique;
    foreach my $item (@ary) {
        push(@unique, $item) unless $seen{$item}++;
    }

    return @unique;
}

=head2 * looks_like_number( $scalar )

Shamelessly stolen from Scalar::Util 1.10 in order to reduce dependancies.
Not part of the normal copyright.

=cut

sub looks_like_number {
    local $_ = shift;

    # checks from perlfaq4
    return $] < 5.009002 unless defined;
    return 1 if (/^[+-]?\d+$/);    # is a +/- integer
    return 1
        if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);   # a C float
    return 1
        if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i)
        or ($] >= 5.006001 and /^Inf$/i);

    0;
}

=head2 uneval

Takes any built-in object and returns the perl representation of it as a string
of text.  It was copied from Interchange L<http://www.icdevgroup.org>, written 
by Mike Heins E<lt>F<mike@perusion.com>E<gt>.  

=cut

sub uneval {
    my ($self, $o) = @_;    # recursive
    my ($r, $s, $key, $value);

    local ($^W) = 0;
    no warnings;            #supress 'use of unitialized values'

    $r = ref $o;
    if (!$r) {
        $o =~ s/([\\"\$@])/\\$1/g;
        $s = '"' . $o . '"';
    }
    elsif ($r eq 'ARRAY') {
        $s = "[";
        for my $i (0 .. $#$o) {
            $s .= uneval($o->[$i]) . ",";
        }
        $s .= "]";
    }
    elsif ($r eq 'HASH') {
        $s = "{";
        while (($key, $value) = each %$o) {
            $s .= "'$key' => " . uneval($value) . ",";
        }
        $s .= "}";
    }
    else {
        $s = "'something else'";
    }

    $s;
}

1;

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
