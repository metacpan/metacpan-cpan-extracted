package Color::Spectrum;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.16';

use POSIX;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw( generate rgb2hsi hsi2rgb );

use Color::Library;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub generate {
    my $self = shift if ref($_[0]) eq __PACKAGE__;
    croak "ColorCount and at least one color needed" if @_ < 2;
    my $cnt  = $_[0];
    my $col1 = $_[1];
    $_[2]  ||= $_[1];
    my $col2 = $_[2];

    # expand 3 hex chars to 6
    $col1 =~ s/^([a-f0-9])([a-f0-9])([a-f0-9])$/$1$1$2$2$3$3/i;
    $col2 =~ s/^([a-f0-9])([a-f0-9])([a-f0-9])$/$1$1$2$2$3$3/i;

    # look up hex color if not a hex color
    $col1 = Color::Library->color( $col1 ) unless $col1 =~ /^#?[a-f0-9]{6}$/i;
    $col2 = Color::Library->color( $col2 ) unless $col2 =~ /^#?[a-f0-9]{6}$/i;

    croak "Invalid color $_[1]" unless $col1;
    croak "Invalid color $_[2]" unless $col2;

    # remove leading hash (we'll add it back later)
    $col1 =~s/^#//;
    $col2 =~s/^#//;

    my $clockwise = 0;
    $clockwise++ if ( $cnt < 0 );
    $cnt = int( abs( $cnt ) );

    my @murtceps = ( uc "#$col1" );
    return ( wantarray() ? @murtceps : \@murtceps ) if $cnt <= 1;
    return ( wantarray() ? (uc "#$col1","#$col2") : [uc "#$col1","#$col2"] ) if $cnt == 2;

    # The RGB values need to be on the decimal scale,
    # so we divide em by 255 enpassant.
    my ( $h1, $s1, $i1 ) = rgb2hsi( map { hex() / 255 } unpack( 'a2a2a2', $col1 ) );
    my ( $h2, $s2, $i2 ) = rgb2hsi( map { hex() / 255 } unpack( 'a2a2a2', $col2 ) );
    $cnt--;
    my $sd = ( $s2 - $s1 ) / $cnt;
    my $id = ( $i2 - $i1 ) / $cnt;
    my $hd = $h2 - $h1;
    if ( uc( $col1 ) eq uc( $col2 ) ) {
        $hd = ( $clockwise ? -1 : 1 ) / $cnt;
    } else {
        $hd = ( ( $hd < 0 ? 1 : 0 ) + $hd - $clockwise) / $cnt;
    }

    while (--$cnt) {
        $s1 += $sd;
        $i1 += $id;
        $h1 += $hd;
        $h1 -= 1 if $h1>1;
        $h1 += 1 if $h1<0;
        push @murtceps, sprintf "#%02X%02X%02X",
            map { int( $_ * 255 +.5) } hsi2rgb( $h1, $s1, $i1 );
    }
    push @murtceps, uc "#$col2";
    return wantarray() ? @murtceps : \@murtceps;
}

sub rgb2hsi {
    my ( $r, $g, $b ) = @_;
    my ( $h, $s, $i ) = ( 0, 0, 0 );

    $i = ( $r + $g + $b ) / 3;
    return ( $h, $s, $i ) if $i == 0;

    my $x = $r - 0.5 * ( $g + $b );
    my $y = 0.866025403 * ( $g - $b );
    $s = ( $x ** 2 + $y ** 2 ) ** 0.5;
    return ( $h, $s, $i ) if $s == 0;

    $h = POSIX::atan2( $y , $x ) / ( 2 * 3.1415926535 );
    return ( $h, $s, $i );
}

sub hsi2rgb {
    my ( $h, $s, $i ) =  @_;
    my ( $r, $g, $b ) = ( 0, 0, 0 );

    # degenerate cases. If !intensity it's black, if !saturation it's grey
    return ( $r, $g, $b ) if ( $i == 0 );
    return ( $i, $i, $i ) if ( $s == 0 );

    $h = $h * 2 * 3.1415926535;
    my $x = $s * cos( $h );
    my $y = $s * sin( $h );

    $r = $i + ( 2 / 3 * $x );
    $g = $i - ( $x / 3 ) + ( $y / 2 / 0.866025403 );
    $b = $i - ( $x / 3 ) - ( $y / 2 / 0.866025403 );

    # limit 0<=x<=1  ## YUCK but we go outta range without it.
    ( $r, $b, $g ) = map { $_ < 0 ? 0 : $_ > 1 ? 1 : $_ } ( $r, $b, $g );

    return ( $r, $g, $b );
}

1;

__END__
=head1 NAME

Color::Spectrum - Just another HTML color generator.

=head1 SYNOPSIS

  # Procedural interface:
  use Color::Spectrum qw( generate );
  my @color = generate(10, '#000000', '#FF0000' );

  # OO interface:
  use Color::Spectrum;
  my $spectrum = Color::Spectrum->new;
  my @color = $spectrum->generate( 10, 'black', 'red' );

=head1 DESCRIPTION

From the author, Mark Mills: "This is a rewrite of a script I wrote
[around 1999] to make spectrums of colors for web page table tags.
It uses a real simple geometric conversion that gets the job done.
It can shade from dark to light, from saturated to dull, and around
the spectrum all at the same time. It can go thru the spectrum in
either direction."

=head1 METHODS

=over 4

=item B<new>

Constructor. No args.

=item B<generate>

This method returns a list of size $elements which contains
web colors starting from $start_color and ranging to $end_color.

 # Procedural interface:
 @list = generate( $elements, $start_color, $end_color );

 # OO interface:
 @list = $spectrum->generate( $elements, $start_color, $end_color );

=item B<hsi2rgb>

Hue, saturation and intesity to red, green and blue.

=item B<rgb2hsi>

Red, green and blue to hue, saturation and intesity.

=back

=head1 About Muliple Color Spectrums

Just call generate() more than once. If you want expand from one
color to the next, and then back to the original color then simply
reuse the returned array (minus the last element if you don't want
the repeated color).

 my @color = $spectrum->generate(4,'#000000','#FFFFFF');

 print for @color, (reverse @color)[1..$#color];

If you want to expand from one color to the next, and then to yet
another color, simply stack calls to generate() and take care to
remove the repeated color each time:

 my @color = (
    $spectrum->generate(13,'#FF0000','#00FF00'),
    ($spectrum->generate(13,'#00FF00','#0000FF'))[1..12],
 );

=head1 REQUIRES

B<Color::Library> - Used to look up non hash value colors.

=head1 BUGS

Please report any bugs or feature requests to either

=over 4

=item * Email: C<bug-color-spectrum at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Color-Spectrum>

=back

=head1 GITHUB

The Github project is L<https://github.com/jeffa/Color-Spectrum>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Color::Spectrum

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Color-Spectrum>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Color-Spectrum>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Color-Spectrum>

=item * Search CPAN L<http://search.cpan.org/dist/Color-Spectrum/>

=back

=head1 AUTHOR

Mark Mills

=head1 MAINTAINANCE

This package is maintained by Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 COPYRIGHT

Copyright 2024 Mark Mills.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
