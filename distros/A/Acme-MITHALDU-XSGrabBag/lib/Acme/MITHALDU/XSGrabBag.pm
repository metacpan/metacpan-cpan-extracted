package Acme::MITHALDU::XSGrabBag;
use strictures;
use Exporter 'import';
use Acme::MITHALDU::XSGrabBag::Inline ();
use Inline::C 0.74 ();

our $VERSION = '1.161310'; # VERSION

# ABSTRACT: a bunch of XS math functions i'm not sure where to shove yet

#
# This file is part of Acme-MITHALDU-XSGrabBag
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

our @EXPORT_OK = qw(
  mix
  deg2rad
  rad2deg
  dot2_product
);

Acme::MITHALDU::XSGrabBag::Inline->import(
    C => join "\n",
    _mix(),
    _deg2rad(),
    _rad2deg(),
    _dot2_product(),
);


sub _mix {
    <<'...';
int mix(int a, int b, int c) {
    a -= b; a -= c; a ^= (c>>13);
    b -= c; b -= a; b ^= (a<<8);
    c -= a; c -= b; c ^= (b>>13);
    a -= b; a -= c; a ^= (c>>12);
    b -= c; b -= a; b ^= (a<<16);
    c -= a; c -= b; c ^= (b>>5);
    a -= b; a -= c; a ^= (c>>3);
    b -= c; b -= a; b ^= (a<<10);
    c -= a; c -= b; c ^= (b>>15);
    return c;
}
...
}


sub _deg2rad {
    <<'...';
float deg2rad(float degrees) {
    return 0.0174532925 * degrees;
}
...
}


sub _rad2deg {
    <<'...';
float rad2deg(float radians) {
    return 57.2957795786 * radians;
}
...
}


sub _dot2_product {
    <<'...';
int dot2_product( int xa, int ya, int xb, int yb ) {
    int sum = 0;
    sum += xa * xb;
    sum += ya * yb;
    return sum;
}
...
}

1;

__END__

=pod

=head1 NAME

Acme::MITHALDU::XSGrabBag - a bunch of XS math functions i'm not sure where to shove yet

=head1 VERSION

version 1.161310

=head1 DESCRIPTION

This module is an experimental space for me to work with XS functions meant for
L<Microidium|https://github.com/wchristian/Microidium>.

=head1 FUNCTIONS

=head2 my $hash = mix( $a, $b, $c )

Takes 3 x 32 bits of data as integers, mixes them, combining all 96 bits of
input to generate a pseudo-random hash returned as a 32 bit integer.

Original implementation by
L<Bob Jenkins|http://web.archive.org/web/20071224045401/http://www.burtleburtle.net/bob/c/lookup2.c>.

=head2 my $deg = deg2rad( $rad )

32 bit degree to radian conversion, dirty, but fast.

=head2 my $rad = rad2deg( $deg )

32 bit radian to degree conversion, dirty, but fast.

=head2 my $dot = dot2_product( $xa, $ya, $xb, $yb )

Simple dot product calculation for 2d vectors.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MITHALDU-XSGrabBag>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Acme-MITHALDU-XSGrabBag>

  git clone https://github.com/wchristian/Acme-MITHALDU-XSGrabBag.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
