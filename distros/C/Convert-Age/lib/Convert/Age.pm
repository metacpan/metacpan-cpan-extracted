package Convert::Age;

use warnings;
use strict;

=head1 NAME

Convert::Age - convert integer seconds into a "compact" form and back.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Convert::Age;

    my $c = Convert::Age::encode(189988007); # 6y7d10h26m47s
    my $d = Convert::Age::decode('5h37m5s'); # 20225

    # or export functions

    use Convert::Age qw(encode_age decode_age);

    my $c = encode_age(20225); # 5h37m5s
    my $d = decode_age('5h37m5s'); # 5h37m5s

=cut


use Exporter 'import';
our @EXPORT_OK = qw(encode_age decode_age);

=head1 EXPORT

=over 4

=item encode_age 

synonym for Convert::Age::encode()

=item decode_age

synonym for Convert::Age::decode()

=back

=head1 NOTE

The methods in this module are suitable for some kinds of logging and
input/output conversions.  It achieves the conversion through simple
remainder arithmetic and the length of a year as 365.2425 days.

=head1 FUNCTIONS

=head2 encode

convert seconds into a "readable" format 344 => 5m44s

=cut

my %convert = (
    y => 365.2425 * 3600 * 24,
    d => 3600 * 24,
    h => 3600,
    m => 60,
    s => 1,
);

sub encode {
    my $age = shift;

    my $out = "";

    my %tag = reverse %convert;

    # largest first
    for my $k (reverse sort {$a <=> $b} keys %tag) {
        next unless ($age >= $k);
        next if (int ($age / $k) == 0);

        $out .= int ($age / $k). $tag{$k};
        $age = $age % $k;
    }

    return $out;
}

=head2 encode_age

synonym for encode that can be exported

=cut

sub encode_age {
    goto &encode;
}

=head2 decode

convert the "readable" format into seconds

=cut

sub decode {
    my $age = shift;

    return $age if ($age =~ /^\d+$/);

    my $seconds = 0;
    my $p = join "", keys %convert;
    my @l = split /([$p])/, $age;

    while (my ($c, $s) = splice(@l, 0, 2)) {
        $seconds += $c * $convert{$s};
    }

    return $seconds;
}

=head2 decode_age

synonym for encode that can be exported

=cut

sub decode_age {
    goto &decode;
}

=head1 AUTHOR

Chris Fedde, C<< <cfedde at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-convert-age at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-Age>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::Age

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-Age>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-Age>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-Age>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-Age>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Chris Fedde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Convert::Age
