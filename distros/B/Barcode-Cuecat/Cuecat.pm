package Barcode::Cuecat;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '1.20';

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Barcode::Cuecat";
    my $string = shift;
    
    my $self = bless [], $class;

    $self->scan($string) if defined $string;

    return $self;
}

sub _decode {
    my $input = shift;
    
    $input =~ tr/a-zA-Z0-9+-/ -_/; 

    $input = unpack 'u', chr(32 + length($input)*3/4) . $input; 
    $input ^= "C" x length($input); 

    return $input;
}

sub _cuecat_decode {
    my $input = shift;
    $input ^= chr(32) x length($input);
    return join '', map {
	$_ = sprintf("%02d", ord($_));
    } split(//, $input);
}

sub scan ($) {
    my $self = shift;
    my $stuff = shift;
    
    return unless defined $stuff;

    my @items = (split(/\./, $stuff))[1..3];

    $self->[0] = _decode($items[0]);
    $self->[1] = _decode($items[1]);
    $self->[2] = _decode($items[2]);

    if ($self->[1] =~ /^CC(.)/) {
	$self->[1] = ':C1';	# Proprietary :CueCat
	$self->[2] = _cuecat_decode($1 . $self->[2]);
    }

    return $self->[2];
}

sub serial {
    return $_[0]->[0];
}

sub type {
    return $_[0]->[1];
}

sub code {
    return $_[0]->[2];
}

1;
__END__

=head1 NAME

Barcode::Cuecat - Perl extension for decoding :CueCat(tm) scans

=head1 SYNOPSIS

  use Barcode::Cuecat;

  my $bc = new Barcode::Cuecat();

  $bc->scan($garbage);
  my $type = $bc->type();	# Get the type of barcode
  my $code = $bc->code();	# The actual number scanned
  my $serial = $bc->serial();	# The serial of the :CueCat

=head1 DESCRIPTION

This module is an attempt to ease the adoption of :CueCat(tm) into
general purpose applications. The term :CueCat(tm) seems to be a
trademark of a company called Digital Convergence. The code in this
module is based on code that has been found in numerous sites. I have
not found a reference to an author, so I cannot give proper credit for
it. Some references point to Larry Wall, so if this code is actually
yours, I hope you don't mind some repackaging of it :).

As for the legality of this code, I received my :CueCat over the mail,
outside the United States. I had to pay the shipping for this device,
even when I did not request it. According to the laws of the country
where this code is being written, I have each and every right to
reverse engineer or otherwise do whatever I please with this
device. This module is one example of what can I excercise under my
legal rights. This code, of course, carries the same warranties and
can be used under the same terms as Perl itself.

The functions supported by this module are below:

=over

=item C<-E<gt>new($string)>

Creates a Barcode::Cuecat object. C<$string> is optional. If supplied,
this saves you from invoking C<-E<gt>scan()>.

=item C<-E<gt>scan($string)>

Initializes the object with a newly scanned string.

=item C<-E<gt>type()>

Returns the type of barcode decoded. For known :CueCat numbers, this
will be ':C1'.

=item C<-E<gt>code()>

Returns the actual number decoded in the barcode. Codes in the 
proprietary :CueCat format are converted automatically to a
sequence of digits.

=item C<-E<gt>serial()>

Returns the serial number of the :CueCat(tm) scanner. Keep in mind
that this information is meaningless after declawing the device.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Luis E. Munoz <lem@cantv.net>. Thanks to Larry Wall <larry@wall.org>
for the compact original code. Thanks to Brian Blakley
<bblakley@mp5.net> for feedback.

=head1 SEE ALSO

perl(1).

=cut
