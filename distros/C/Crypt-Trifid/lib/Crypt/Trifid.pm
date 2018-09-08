package Crypt::Trifid;

$Crypt::Trifid::VERSION   = '0.10';
$Crypt::Trifid::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Crypt::Trifid - Interface to the Trifid cipher.

=head1 VERSION

Version 0.10

=cut

use 5.006;
use Data::Dumper;
use Crypt::Trifid::Utils qw(generate_chart);

use Moo;
use namespace::autoclean;

has 'chart' => (is => 'ro', default => sub { generate_chart(); });

=head1 DESCRIPTION

In classical cryptography, the trifid cipher is a cipher invented around  1901 by
Felix  Delastelle,  which  extends  the  concept  of  the bifid cipher to a third
dimension, allowing each symbol to be fractionated into 3 elements instead of two.

While the  bifid uses the Polybius square to turn each symbol into coordinates on
a 5x5 (or 6x6) square, the trifid turns them into coordinates on a 3x3x3 cube.

As with the bifid, this is then combined with transposition to achieve diffusion.

However  a  higher  degree  of  diffusion  is achieved because each output symbol
depends on 3 input symbols instead of two.

Thus the trifid was the first practical trigraphic substitution.

Source: L<Wikipedia|http://en.wikipedia.org/wiki/Trifid_cipher>

=head1 SYNOPSIS

    use strict; use warnings;
    use Crypt::Trifid;

    my $crypt   = Crypt::Trifid->new;
    my $message = 'TRIFID';
    my $encoded = $crypt->encode($message);
    my $decoded = $crypt->decode($encoded);

    print "Encoded message: [$encoded]\n";
    print "Decoded message: [$decoded]\n";

=head1 METHODS

=head2 encode($message)

It takes message as scalar string and returns the encoded message.

    use strict; use warnings;
    use Crypt::Trifid;

    my $crypt   = Crypt::Trifid->new;
    my $message = 'TRIFID';
    my $encoded = $crypt->encode($message);

    print "Encoded message: [$encoded]\n";

=cut

sub encode {
    my ($self, $message) = @_;

    die "ERROR: Missing message.\n" unless defined $message;
    die "ERROR: Invalid message.\n" if ref($message);

    my $chart   = $self->chart;
    my @values  = _encode($message, $chart);

    my $start   = 0;
    my $encoded = '';
    my $_chart  = { reverse %$chart };

    while ($start < scalar(@values)) {
        my $end   = $start + 2;
        my $value = join '', @values[$start..$end];
        $encoded .= $_chart->{$value};
        $start = $end + 1;
    }

    return $encoded;
}

=head2 decode($encoded_message)

It takes an encoded message as scalar string and returns the decoded message.

    use strict; use warnings;
    use Crypt::Trifid;

    my $crypt   = Crypt::Trifid->new;
    my $message = 'TRIFID';
    my $encoded = $crypt->encode($message);
    my $decoded = $crypt->decode($encoded);

    print "Encoded message: [$encoded]\n";
    print "Decoded message: [$decoded]\n";

=cut

sub decode {
    my ($self, $message) = @_;

    die "ERROR: Missing message.\n" unless defined $message;
    die "ERROR: Invalid message.\n" if ref($message);

    my $chart  = $self->chart;
    my $_chart = { reverse %$chart };
    my @nodes  = _decode($message, $chart);

    my $index  = 0;
    my $_chars = [];
    my $i      = 0;
    my $j      = scalar(@nodes)/3;
    while ($index < scalar(@nodes)) {
        push @{$_chars->[$i]}, @nodes[$index..($index+$j-1)];
        $index += $j;
        $i++;
    }

    my $decoded = '';
    foreach (1..$j) {
        my $x = $_chars->[0]->[$_-1];
        my $y = $_chars->[1]->[$_-1];
        my $z = $_chars->[2]->[$_-1];
        $decoded .= $_chart->{sprintf("%d%d%d", $x, $y, $z)};
    }

    return $decoded;
}

#
#
# PRIVATE METHODS

sub _encode {
    my ($message, $chart) = @_;

    my @chars  = split //,$message;
    my $chars  = [];
    my $column = 0;
    foreach (@chars) {
        my $node = $chart->{uc($_)};
        my @node = split //,$node;

        $chars->[0]->[$column] = $node[0];
        $chars->[1]->[$column] = $node[1];
        $chars->[2]->[$column] = $node[2];

        $column++;
    }

    my $values = join '', @{$chars->[0]}, @{$chars->[1]}, @{$chars->[2]};
    my @values = split //, $values;

    return @values;
}

sub _decode {
    my ($message, $chart) = @_;

    my @chars  = split //,$message;
    my $node   = '';
    foreach (@chars) {
        my $_node = $chart->{uc($_)};
        $node .= sprintf("%d", $_node);
    }

    my @nodes  = split //, $node;

    return @nodes;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Crypt-Trifid>

=head1 BUGS

Please report any bugs/feature requests to C<bug-crypt-trifid at rt.cpan.org>  or
through the web interface at  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Trifid>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Trifid

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Trifid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Trifid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Trifid>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Trifid/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2017 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Crypt::Trifid
