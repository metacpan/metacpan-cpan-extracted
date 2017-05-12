require 5.010;

=head1 NAME

Barcode::Code128 - Generate CODE 128 bar codes

=head1 SYNOPSIS

  use Barcode::Code128;

  $code = new Barcode::Code128;

=head1 REQUIRES

Perl 5.004, Carp, Exporter, GD (optional)

=head1 EXPORTS

By default, nothing.  However there are a number of constants that
represent special characters used in the CODE 128 symbology that you
may wish to include.  For example if you are using the EAN-128 or
UCC-128 code, the string to encode begins with the FNC1 character.  To
encode the EAN-128 string "00 0 0012345 555555555 8", you would do the
following:

  use Barcode::Code128 'FNC1';
  $code = new Barcode::Code128;
  $code->text(FNC1.'00000123455555555558');

To have this module export one or more of these characters, specify
them on the C<use> statement or use the special token ':all' instead
to include all of them.  Examples:

  use Barcode::Code128 qw(FNC1 FNC2 FNC3 FNC4 Shift);
  use Barcode::Code128 qw(:all);

Here is the complete list of the exportable characters.  They are
assigned to high-order ASCII characters purely arbitrarily for the
purposes of this module; the values used do not reflect any part of
the CODE 128 standard.  B<Warning>: Using the C<CodeA>, C<CodeB>,
C<CodeC>, C<StartA>, C<StartB>, C<StartC>, and C<Stop> codes may cause
your barcodes to be invalid, and be rejected by scanners.  They are
inserted automatically as needed by this module.

  CodeA      0xf4        CodeB      0xf5         CodeC      0xf6
  FNC1       0xf7        FNC2       0xf8         FNC3       0xf9
  FNC4       0xfa        Shift      0xfb         StartA     0xfc
  StartB     0xfd        StartC     0xfe         Stop       0xff

=head1 DESCRIPTION

Barcode::Code128 generates bar codes using the CODE 128 symbology.  It
can generate images in PNG or GIF format using the GD package, or it
can generate a text string representing the barcode that you can
render using some other technology if desired.

The intended use of this module is to create a web page with a bar
code on it, which can then be printed out and faxed or mailed to
someone who will scan the bar code.  The application which spurred its
creation was an expense report tool, where the employee submitting the
report would print out the web page and staple the receipts to it, and
the Accounts Payable clerk would scan the bar code to indicate that
the receipts were received.

The default settings for this module produce a large image that can
safely be FAXed several times and still scanned easily.  If this
requirement is not important you can generate smaller image using
optional parameters, described below.

If you wish to generate images with this module you must also have the
GD module (written by Lincoln Stein, and available from CPAN)
installed.  Using the libgd library, GD can generate files in PNG
(Portable Network Graphics) or GIF (Graphic Interchange Format)
formats.

Starting with version 1.20, and ending with 2.0.28 (released July
21st, 2004), GD and the underlying libgd library could not generate
GIF files due to patent issues, but any modern version of libgd (since
2004) can do GIF as the patent has expired.  Most browsers have no
trouble with PNG files.

In order to ensure you have a sufficiently modern installation of the
GD module to do both GIF and PNG formats, we require version 2.18 of
GD (which in turn requires libgd 2.0.28) or higher.

If the GD module is not present, you can still use the module, but you
will not be able to use its functions for generating images.  You can
use the barcode() method to get a string of "#" and " " (hash and
space) characters, and use your own image-generating routine with that
as input.

To use the the GD module, you will need to install it along with this
module.  You can obtain it from the CPAN (Comprehensive Perl Archive
Network) repository of your choice under the directory
C<authors/id/LDS>.  Visit http://www.cpan.org/ for more information
about CPAN.  The GD home page is:
http://stein.cshl.org/WWW/software/GD/GD.html

=head1 METHODS

=over 4

=cut

package Barcode::Code128;

use strict;

use vars qw($GD_VERSION $VERSION %CODE_CHARS %CODE @ENCODING @EXPORT_OK
            %EXPORT_TAGS %FUNC_CHARS @ISA %OPTIONS);

use constant CodeA  => chr(0xf4);
use constant CodeB  => chr(0xf5);
use constant CodeC  => chr(0xf6);
use constant FNC1   => chr(0xf7);
use constant FNC2   => chr(0xf8);
use constant FNC3   => chr(0xf9);
use constant FNC4   => chr(0xfa);
use constant Shift  => chr(0xfb);
use constant StartA => chr(0xfc);
use constant StartB => chr(0xfd);
use constant StartC => chr(0xfe);
use constant Stop   => chr(0xff);

use Carp;
use Exporter;

# Try to load GD.  If it succeeds, set $GD_VERSION accordingly.
BEGIN {
    $GD_VERSION = undef;
    eval "use GD 2.18";
    $GD_VERSION = $GD::VERSION
        unless $@;
}

%OPTIONS =
    (
     width            => undef,
     height           => undef,
     border           => 2,
     scale            => 2,
     font             => 'large',
     show_text        => 1,
     font_margin      => 2,
     top_margin       => 0,
     bottom_margin    => 0,
     left_margin      => 0,
     right_margin     => 0,
     padding          => 20,
     font_align       => 'left',
     transparent_text => 1,
    );

@EXPORT_OK = qw(CodeA CodeB CodeC FNC1 FNC2 FNC3 FNC4 Shift StartA
                StartB StartC Stop);
%EXPORT_TAGS = (all => \@EXPORT_OK);
@ISA = qw(Exporter);

# Version information
$VERSION = '2.21';

@ENCODING = qw(11011001100 11001101100 11001100110 10010011000
               10010001100 10001001100 10011001000 10011000100
               10001100100 11001001000 11001000100 11000100100
               10110011100 10011011100 10011001110 10111001100

               10011101100 10011100110 11001110010 11001011100
               11001001110 11011100100 11001110100 11101101110
               11101001100 11100101100 11100100110 11101100100
               11100110100 11100110010 11011011000 11011000110

               11000110110 10100011000 10001011000 10001000110
               10110001000 10001101000 10001100010 11010001000
               11000101000 11000100010 10110111000 10110001110
               10001101110 10111011000 10111000110 10001110110

               11101110110 11010001110 11000101110 11011101000
               11011100010 11011101110 11101011000 11101000110
               11100010110 11101101000 11101100010 11100011010
               11101111010 11001000010 11110001010 10100110000

               10100001100 10010110000 10010000110 10000101100
               10000100110 10110010000 10110000100 10011010000
               10011000010 10000110100 10000110010 11000010010
               11001010000 11110111010 11000010100 10001111010

               10100111100 10010111100 10010011110 10111100100
               10011110100 10011110010 11110100100 11110010100
               11110010010 11011011110 11011110110 11110110110
               10101111000 10100011110 10001011110 10111101000

               10111100010 11110101000 11110100010 10111011110
               10111101110 11101011110 11110101110 11010000100
               11010010000 11010011100 1100011101011);

%CODE_CHARS = ( A => [ (map { chr($_) } 040..0137, 000..037),
                       FNC3, FNC2, Shift, CodeC, CodeB, FNC4, FNC1,
                       StartA, StartB, StartC, Stop ],
                B => [ (map { chr($_) } 040..0177),
                       FNC3, FNC2, Shift, CodeC, FNC4, CodeA, FNC1,
                       StartA, StartB, StartC, Stop ],
                C => [ ("00".."99"),
                       CodeB, CodeA, FNC1, StartA, StartB, StartC, Stop ]);

# Provide string equivalents to the constants
%FUNC_CHARS = ('CodeA'  => CodeA,
               'CodeB'  => CodeB,
               'CodeC'  => CodeC,
               'FNC1'   => FNC1,
               'FNC2'   => FNC2,
               'FNC3'   => FNC3,
               'FNC4'   => FNC4,
               'Shift'  => Shift,
               'StartA' => StartA,
               'StartB' => StartB,
               'StartC' => StartC,
               'Stop'   => Stop );

# Convert the above into a 2-dimensional hash
%CODE = ( A => { map { $CODE_CHARS{A}[$_] => $_ } 0..106 },
          B => { map { $CODE_CHARS{B}[$_] => $_ } 0..106 },
          C => { map { $CODE_CHARS{C}[$_] => $_ } 0..106 } );

##----------------------------------------------------------------------------

=item new

Usage:

    $object = new Barcode::Code128

Creates a new barcode object.

=cut

sub new
{
    my $type = shift;
    my $self = bless { @_ }, $type;
    $self->{encoded} ||= [];
    $self->{text}    ||= '';
    $self;
}

=item option

Sets or retreives various options.  If called with only one parameter,
retrieves the value for that parameter.  If called with more than one
parameter, treats the parameters as name/value pairs and sets those
option values accordingly.  If called with no parameters, returns a
hash consisting of the values of all the options (hash ref in scalar
context).  When an option has not been set, its default value is
returned.

You can also set or retrieve any of these options by using it as a
method name.  For example, to set the value of the padding option, you
can use either of these:

    $barcode->padding(10);
    $barcode->option("padding", 10);

The valid options, and the default value and meaning of each, are:

    width            undef    Width of the image (*)
    height           undef    Height of the image (*)
    border           2        Size of the black border around the barcode
    scale            2        How many pixels for the smallest barcode stripe
    font             "large"  Font (**) for the text at the bottom
    show_text        1        True/False: display the text at the bottom?
    font_margin      2        Pixels above, below, and to left of the text
    font_align       "left"   Align the text ("left", "right", or "center")
    transparent_text 1/0(***) True/False: use transparent background for text?
    top_margin       0        No. of pixels above the barcode
    bottom_margin    0        No. of pixels below the barcode (& text)
    left_margin      0        No. of pixels to the left of the barcode
    right_margin     0        No. of pixels to the right of the barcode
    padding          20       Size of whitespace before & after barcode

* Width and height are the default values for the $x and $y arguments
to the png, gif, or gd_image method (q.v.)

** Font may be one of the following: "giant", "large", "medium",
"small", or "tiny".  Or, it may be any valid GD font name, such as
"gdMediumFont".

*** The "transparent_text" option is "1" (true) by default for GIF
output, but "0" (false) for PNG.  This is because PNG transparency is
not supported well by many viewing software The background color is
grey (#CCCCCC) when not transparent.

=cut

sub AUTOLOAD
{
    my($self, @args) = @_;
    use vars qw($AUTOLOAD);
    (my $opt = lc $AUTOLOAD) =~ s/^.*:://;
    return if $opt eq 'destroy';
    $self->option($opt, @args);
}

sub option
{
    my $self = shift;
    my $class = ref $self;      # do this so others can inherit from us
    my $defaults;
    {  no strict 'refs'; $defaults = \%{$class.'::OPTIONS'};  }

    if (!@_) {
        my %all;
        while (my($opt, $def_value) = each %$defaults) {
            if (exists $self->{OPTIONS}{$opt}) {
                $all{$opt} = $self->{OPTIONS}{$opt};
            }
            else {
                $all{$opt} = $def_value;
            }
        }
        wantarray ? %all : \%all;
    }
    elsif (@_ == 1) {           # return requested value
        my $opt = shift;
        croak "Unrecognized option ($opt) for $class"
            unless exists $defaults->{$opt};
        if (exists $self->{OPTIONS}{$opt}) {
            return $self->{OPTIONS}{$opt};
        }
        else {
            return $defaults->{$opt};
        }
    }
    else {
        my $count = 0;
        while(my($opt, $value) = splice(@_, 0, 2)) {
            croak "Unrecognized option ($opt) for $class"
                unless exists $defaults->{$opt};
            $self->{OPTIONS}{$opt} = $value;
            $count++;
        }
        return $count;
    }
}

##----------------------------------------------------------------------------

=item gif

=item png

=item gd_image

Usage:

    $object->png($text)
    $object->png($text, $x, $y)
    $object->png($text, { options... })

    $object->gif($text)
    $object->gif($text, $x, $y)
    $object->gif($text, { options... })

    $object->gd_image($text)
    $object->gd_image($text, $x, $y)
    $object->gd_image($text, { options... })

These methods generate an image using the GD module.  The gd_image()
method returns a GD object, which is useful if you want to do
additional processing to it using the GD object methods.  The other
two create actual images.  NOTE: GIF files require an old version of
GD, and so you probably are not able to create them - see below.

The gif() and png() methods are wrappers around gd_image() that create
the GD object and then run the corresponding GD method to create
output that can be displayed or saved to a file.  Note that only one
of these two methods will work, depending on which version of GD you
have - see below.  The return value from gif() or png() is a binary
file, so if you are working on an operating system (e.g. Microsoft
Windows) that makes a distinction between text and binary files be
sure to call binmode(FILEHANDLE) before writing the image to it, or
the file may get corrupted.  Example:

  open(PNG, ">code128.png") or die "Can't write code128.png: $!\n";
  binmode(PNG);
  print PNG $object->png("CODE 128");
  close(PNG);

If you have GD version 1.20 or newer, the PNG file format is the only
allowed option.  Conversely if you have GD version prior to 1.20, then
the GIF format is the only option.  Check the $object->image_format()
method to find out which you have (q.v.).

Note: All of the arguments to this function are optional.  If you have
previously specified C<$text> to the C<barcode()>, C<encode()>, or
C<text()> methods, you do not need to specify it again.  The C<$x> and
C<$y> variables specify the size of the barcode within the image in
pixels.  If size(s) are not specified, they will be set to the minimum
size, which is the length of the barcode plus 40 pixels horizontally,
and 15% of the length of the barcode vertically.  See also the
$object->width() and $object->height() methods for another way of
specifying this.

If instead of specifying $x and $y, you pass a reference to a hash of
name/value pairs, these will be used as the options, overriding
anything set using the $object->option() (or width/height) method
(q.v.).  However, this will not set the options so any future barcodes
using the same object will revert to the option list of the object.
If you want to set the options permanently use the option, width,
and/or height methods instead.

=cut

sub gd_image
{
    my($self, $text, $x, $y) = @_;
    my %opts;
    if (ref($x) && !defined($y)) {
        %opts = ($self->option, %$x);
        $x = $opts{width};
        $y = $opts{height};
    }
    else {
        %opts = $self->option;
        $opts{width}  = $x if $x;
        $opts{height} = $y if $y;
    }

    croak "The gd_image() method of Barcode::Code128 requires the GD module"
        unless $GD_VERSION;

    my $scale = $opts{scale};
    croak "Scale ($scale) must be a positive integer"
        unless $scale > 0 && int($scale) == $scale;

    my $border = $opts{border};
    croak "Border ($border) must be a positive integer or zero"
        unless $border >= 0 && int($border) == $border;
    $border *= $scale;

    $x ||= $opts{width};
    $y ||= $opts{height};

    my($font, $font_margin, $font_height, $font_width) = (undef, 0, 0, 0);
    if ($opts{show_text}) {
        $font = $opts{font};
        my %fontTable = (giant  => 'gdGiantFont',
                         large  => 'gdLargeFont',
                         medium => 'gdMediumBoldFont',
                         small  => 'gdSmallFont',
                         tiny   => 'gdTinyFont');
        $font = $fontTable{$font} if exists $fontTable{$font};
        croak "Invalid font $font" unless GD->can($font);
        $font = eval "GD->$font"; die $@ if $@;
        $font_margin = $opts{font_margin};
        $font_height = $font->height + $font_margin * 2;
        $font_width  = $font->width;
    }

    my($lm, $rm, $tm, $bm) = map { $opts{$_."_margin"} }
        qw(left right top bottom);

    my @barcode = split //, $self->barcode($text);
    my $n = scalar(@barcode);   # width of string
    my $min_x = ($n + $opts{padding}) * $scale + 2 * $border;
    my $min_y = $n * $scale * 0.15 + 2 * $border; # 15% of width in pixels
    $x ||= $min_x;
    $y ||= $min_y;
    croak "Image width $x is too small for bar code"  if $x < $min_x;
    croak "Image height $y is too small for bar code" if $y < $min_y;
    my $image = new GD::Image($x + $lm + $rm, $y + $tm + $bm + $font_height)
        or croak "Unable to create $x x $y image";
    my $grey  = $image->colorAllocate(0xCC, 0xCC, 0xCC);
    my $white = $image->colorAllocate(0xFF, 0xFF, 0xFF);
    my $black = $image->colorAllocate(0x00, 0x00, 0x00);
    my $red = $image->colorAllocate(0xFF, 0x00, 0x00);
    $image->transparent($grey)
        if $opts{transparent_text};
    if ($border) {
        $image->rectangle($lm, $tm, $lm+$x-1, $tm+$y-1, $black);
        $image->rectangle($lm+$border, $tm+$border,
                          $lm+$x-$border-1, $tm+$y-$border-1, $black);
        $image->fill($lm+1, $tm+1, $black);
    }
    else {
        $image->rectangle($lm, $tm, $lm+$x-1, $tm+$y-1, $white);
    }
    $image->fill($lm+$border+1, $tm+$border+1, $white);
    for (my $i = 0; $i < $n; ++$i)
    {
        next unless $barcode[$i] eq '#';
        my $pos = $x/2 - $n * ($scale/2) + $i * $scale;
        $image->rectangle($lm+$pos, $tm+$border,
                          $lm+$pos+$scale-1, $tm+$y-$border-1, $black);
        $image->fill($lm+$pos+1, $tm+$border+1, $black)
            if $scale > 2;
    }
    if (defined $font) {
        my ($font_x,$font_y);
        if ($opts{font_align} eq "center") {
            $font_x = int(($x+$lm+$rm-($font_width*length $self->{text}))/2);
        } elsif ($opts{font_align} eq "right") {
            $font_x = $x +$lm-($font_width * length $self->{text});
        } else { # Assume left
            $font_x = $lm+$font_margin;
        }
        $font_y = $tm+$y+$font_margin;
        $image->string($font, $font_x, $font_y, $self->{text}, $black)
    }
    return $image;
}

sub gif
{
    my($self, $text, $x, $y, $scale) = @_;
    croak "The gif() method of Barcode::Code128 requires the GD module"
        unless $GD_VERSION;
    my $image = $self->gd_image($text, $x, $y, $scale);
    return $image->gif();
}

sub png
{
    my($self, $text, $x, $y, $scale) = @_;
    croak "The png() method of Barcode::Code128 requires the GD module"
        unless $GD_VERSION;
    my $image = $self->gd_image($text, $x, $y, $scale);
    return $image->png();
}

##----------------------------------------------------------------------------

=item barcode

Usage:

    $object->barcode($text)

Computes the bar code for the specified text.  The result will be a
string of '#' and space characters representing the dark and light
bands of the bar code.  You can use this if you have an alternate
printing system besides using GD to create the images.

Note: The C<$text> parameter is optional. If you have previously
specified C<$text> to the C<encode()> or C<text()> methods, you do not
need to specify it again.

=cut

sub barcode
{
    my($self, $text) = @_;
    $self->encode($text) if defined $text;
    my @encoded = @{ $self->{encoded} };
    croak "No encoded text found" unless @encoded;
    join '', map { $_ = $ENCODING[$_]; tr/01/ \#/; $_ } @encoded;
}

###---------------------------------------------------------------------------

=back

=head2 Housekeeping Functions

The rest of the methods defined here are only for internal use, or if
you really know what you are doing.  Some of them may be useful to
authors of classes that inherit from this one, or may be overridden by
subclasses.  If you just want to use this module to generate bar
codes, you can stop reading here.

=over 4

=cut

##----------------------------------------------------------------------------

=item encode

Usage:

    $object->encode
    $object->encode($text)
    $object->encode($text, $preferred_code)

Do the encoding.  If C<$text> is supplied, will automatically call the
text() method to set that as the text value first.  If
C<$preferred_code> is supplied, will try that code first.  Otherwise,
the codes will be tried in the following manner:

1. If it is possible to use Code C for any of the text, use that for
as much of it as possible.

2. Check how many characters would be converted using codes A or B,
and use that code to convert them.  If the amount is equal, code A is
used.

3. Repeat steps 1 and 2 until the text string has been completely encoded.

=cut

sub encode
{
    my($self, $text, $preferred_code) = @_;
    $self->text($text) if defined $text;
    croak "No text defined" unless defined($text = $self->text);
    croak "Invalid preferred code ``$preferred_code''"
        if defined $preferred_code && !exists $CODE{$preferred_code};
    # Reset internal variables
    my $encoded = $self->{encoded} = [];
    $self->{code} = undef;
    my $sanity = 0;
    while(length $text)
    {
        confess "Sanity Check Overflow" if $sanity++ > 1000;
        my @chars;
        if ($preferred_code && (@chars = _encodable($preferred_code, $text)))
        {
            $self->start($preferred_code);
            push @$encoded, map { $CODE{$preferred_code}{$_} } @chars;
        }
        elsif (@chars = _encodable('C', $text))
        {
            $self->start('C');
            push @$encoded, map { $CODE{C}{$_} } @chars;
        }
        else
        {
            my %x = map { $_ => [ _encodable($_, $text) ] } qw(A B);
            my $code = (@{$x{A}} >= @{$x{B}} ? 'A' : 'B'); # prefer A if equal
            $self->start($code);
            @chars = @{ $x{$code} };
            push @$encoded, map { $CODE{$code}{$_} } @chars;
        }
        croak "Unable to find encoding for ``$text''" unless @chars;
        substr($text, 0, length join '', @chars) = '';
    }
    $self->stop;
    wantarray ? @$encoded : $encoded;
}

##----------------------------------------------------------------------------

=item text

Usage:

    $object->text($text)
    $text = $object->text

Set or retrieve the text for this barcode.  This will be called
automatically by encode() or barcode() so typically this will not be
used directly by the user.

=cut

sub text
{
    my($self, $text) = @_;
    $self->{text} = $text if defined $text;
    $self->{text};
}

##----------------------------------------------------------------------------

=item start

Usage:

    $object->start($code)

If the code (see code()) is already defined, then adds the CodeA,
CodeB, or CodeC character as appropriate to the encoded message inside
the object.  Typically for internal use only.

=cut

sub start
{
    my($self, $new_code) = @_;
    my $old_code = $self->code;
    if (defined $old_code)
    {
        my $func = $FUNC_CHARS{"Code$new_code"} or
            confess "Unable to switch from ``$old_code'' to ``$new_code''";
        push @{ $self->{encoded} }, $CODE{$old_code}{$func};
    }
    else
    {
        my $func = $FUNC_CHARS{"Start$new_code"} or
            confess "Unable to start with ``$new_code''";
        @{ $self->{encoded} } = $CODE{$new_code}{$func};
    }
    $self->code($new_code);
}

##----------------------------------------------------------------------------

=item stop

Usage:

    $object->stop()

Computes the check character and appends it along with the Stop
character, to the encoded string.  Typically for internal use only.

=cut

sub stop
{
    my($self) = @_;
    my $sum = $self->{encoded}[0];
    for (my $i = 1; $i < @{ $self->{encoded} }; ++$i)
    {
        $sum += $i * $self->{encoded}[$i];
    }
    my $stop = Stop;
    push @{ $self->{encoded} }, ($sum % 103), $CODE{C}{$stop};
}

##----------------------------------------------------------------------------

=item code

Usage:

    $object->code($code)
    $code = $object->code

Set or retrieve the code for this barcode.  C<$code> may be 'A', 'B',
or 'C'.  Typically for internal use only.  Not particularly meaningful
unless called during the middle of encoding.

=cut

sub code
{
    my($self, $new_code) = @_;
    if (defined $new_code)
    {
        $new_code = uc $new_code;
        croak "Unknown code ``$new_code'' (should be A, B, or C)"
            unless $new_code eq 'A' || $new_code eq 'B' || $new_code eq 'C';
        $self->{code} = $new_code;
    }
    $self->{code};
}

##----------------------------------------------------------------------------
## _encodable($code, $string)
##
## Internal use only.  Returns array of characters from $string that
## can be encoded using the specified $code (A B or C).  Note: not an
## object-oriented method.

sub _encodable
{
    my($code, $string) = @_;
    my @chars;
    while (length $string)
    {
        my $old = $string;
        push @chars, $1 while($code eq 'C' && $string =~ s/^(\d\d)//);
        my $char;
        while(defined($char = substr($string, 0, 1)))
        {
            last if $code ne 'C' && $string =~ /^\d\d\d\d\d\d/;
            last unless exists $CODE{$code}{$char};
            push @chars, $char;
            $string =~ s/^\Q$char\E//;
        }
        last if $old eq $string; # stop if no more changes made to $string
    }
    @chars;
}

=back

=head1 CLASS VARIABLES

None.

=head1 DIAGNOSTICS

=over 4

=item Unrecognized option ($opt) for $class

The specified option is not valid for the module.  C<$class> should be
"Barcode::Code128" but if it has been inherited into another module,
that module will show instead.  C<$opt> is the attempted option.

=item The gd_image() method of Barcode::Code128 requires the GD module

To call the C<gd_image()>, C<png()>, or C<gif()> methods, the GD
module must be present.  This module is used to create the actual
image.  Without it, you can only use the C<barcode()> method.

=item Scale must be a positive integer

The scale factor for the C<gd_image()>, C<png()>, or C<gif()> methods
must be a positive integer.

=item Border ($border) must be a positive integer or zero

The border option cannot be a fractional or negative number.

=item Invalid font $font

The specified font is not valid.  Note that this is tested using
GD->can(), and so any subroutine in GD.pm will pass this test - but
only the fonts will actually work.  See the GD module documentation
for more.

=item Image width $x is too small for bar code

You have specified an image width that does not allow enough space for
the bar code to be displayed.  The minimum allowable is the size of
the bar code itself plus 40 pixels.  If in doubt, just omit the width
value when calling C<gd_image()>, C<png()>, or C<gif()> and it will
use the minimum.

=item Image height $y is too small for bar code

You have specified an image height that does not allow enough space
for the bar code to be displayed.  The minimum allowable is 15% of the
width of the bar code.  If in doubt, just omit the height value when
calling C<gd_image()>, C<png()>, or C<gif()> and it will use the
minimum.

=item Unable to create $x x $y image

An error occurred when initializing a GD::Image object for the
specified size.  Perhaps C<$x> and C<$y> are too large for memory?

=item The gif() method of Barcode::Code128 requires the GD module

=item The gif() method of Barcode::Code128 requires version less than 1.20 of GD

=item The png() method of Barcode::Code128 requires the GD module

=item The png() method of Barcode::Code128 requires at least version 1.20 of GD

These errors indicate that the GD module, or the correct version of
the GD module for this method, was not present.  You need to install
GD version 1.20 or greater to create PNG files, or a version of GD
less than 1.20 to create GIF files.

=item No encoded text found

This message from C<barcode()> typically means that there was no text
message supplied either during the current method call or in a
previous method call on the same object.  This error occurs when you
are trying to create a barcode by calling one of C<gd_image()>,
C<png()>, C<gif()>, or C<barcode()> without having specified the text
to be encoded.

=item No text defined

This message from C<encode()> typically means that there was no text
message supplied either during the current method call or in a
previous method call on the same object.

=item Invalid preferred code ``$preferred_code''

This error means C<encode()> was called with the C<$preferred_code>
optional parameter but it was not one of ``A'', ``B'', or ``C''.

=item Sanity Check Overflow

This is a serious error in C<encode()> that indicates a serious
problem attempting to encode the requested message.  This means that
an infinite loop was generated.  If you get this error please contact
the author.

=item Unable to find encoding for ``$text''

Part or all of the message could not be encoded.  This may mean that
the message contained characters not encodable in the CODE 128
character set, such as a character with an ASCII value higher than 127
(except the special control characters defined in this module).

=item Unable to switch from ``$old_code'' to ``$new_code''

This is a serious error in C<start()> that indicates a serious problem
occurred when switching between the codes (A, B, or C) of CODE 128.
If you get this error please contact the author.

=item Unable to start with ``$new_code''

This is a serious error in C<start()> that indicates a serious problem
occurred when starting encoding in one of the codes (A, B, or C) of
CODE 128.  If you get this error please contact the author.

=item Unknown code ``$new_code'' (should be A, B, or C)

This is a serious error in C<code()> that indicates an invalid
argument was supplied.  Only the codes (A, B, or C) of CODE 128 may be
supplied here.  If you get this error please contact the author.

=back

=head1 BUGS

At least some Web browsers do not seem to handle PNG files with
transparent backgrounds correctly.  As a result, the default for PNG
is to generate barcodes without transparent backgrounds - the
background is grey instead.

=head1 AUTHOR

William R. Ward, wrw@bayview.com

=head1 SEE ALSO

perl(1), GD

=cut

1;
