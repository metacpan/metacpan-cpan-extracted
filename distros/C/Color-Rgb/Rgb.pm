package Color::Rgb;

# $Id: Rgb.pm,v 1.4 2002/10/23 20:30:46 sherzodr Exp $

require 5.003;
use strict;
use Carp 'croak';
use Fcntl qw(:DEFAULT :flock);
use vars qw($RGB_TXT $VERSION);

###########################################################################
################ Color::Rgb - simple rgb.txt parser #######################
###########################################################################
#                                                                         #
#   Copyright (c) 2002 Sherzod Ruzmetov. All rights reserved              #
#   You can modify and redistribute the following library under the same   #
#   terms as Perl itself.                                                 #
#                                                                         #
#   The library is written with usefulness in mind, but  neither explicit #
#   nor implied guarantee to a particular purpose made.                   #
###########################################################################

$RGB_TXT = '/usr/X11R6/lib/X11/rgb.txt';

($VERSION) = '$Revision: 1.4 $' =~ m/Revision:\s*(\S+)/;





# new(): constructor
# Usage: CLASS->new(rgb_txt=>'/path/to/rgb.txt')
# RETURN VALUE: Color::Rgb object
sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $self = {
        rgb_txt => $RGB_TXT,
        _rgb_map=> {},
        @_,
    };

    unless (sysopen (RGB, $self->{rgb_txt}, O_RDONLY) ) {
        croak "$self->{rgb_txt}: $!";
    }

    unless ( flock(RGB, LOCK_SH) ) {
        croak "Couldn't acquire LOCK_SH on $self->{rgb_txt}: $!";
    }

    while ( <RGB> ) {
        /^(\n|!|\#)/  and next;     # empty lines and comments
        chomp();
        my ($r, $g, $b, $name) = $_ =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.+)$/;
        $self->{_rgb_map}->{ lc($name) } = [$r, $g, $b];
    }

    close (RGB) or croak "$self->{rgb_txt}: $!";

    return bless $self => $class;
}









# rgb(): reruns RGB value for an name
# Usage: CLASS->rgb('red' [, ','])
# RETURN VALUE either list or string
sub rgb {
    my ($self, $name, $delim) = @_;

    unless ( $name ) {
        croak "Color::Rgb->rgb(): usage: rgb(\$name [,\$delim]";
    }

    my $rgb = $self->{_rgb_map}->{lc($name) };

    unless ( defined $rgb ) {
        croak "$name doesn't exist";
    }

    my @rgb = @{ $rgb };

    defined $delim and return join ($delim, @rgb);

    return @rgb;
}


sub name2rgb {
    my $self = shift;

    $self->rgb(@_);
}


# hex(): returns a hex value for an name
# Usage: CLASS->hex('red' [,'#'])
# RETURN VALUE: hex string
sub hex {
    my ($self, $name, $pound) = @_;

    unless ( $name ) {
        croak "Color::Rgb->hex(): usage: hex(\$name [,\$prefix]";
    }

    # Using rgb() method to get the RGB list
    my ($r, $g, $b) = $self->rgb(lc($name)) or return;

    return sprintf("$pound%02lx%02lx%02lx", $r, $g, $b);
}


sub name2hex {
    my $self= shift;

    $self->hex(@_);
}


# hex2rgb(): takes a hex string, and returns an rgb list or string
# depending if $delim was given or not
# Usage: CLASS->hex2rgb('#000000' [,',']);
# RETURN VALUE: list or string
sub hex2rgb {
    my ($self, $hex, $delim) = @_;

    unless ( $hex ) {
        croak "Color::Rgb->hex2rgb(): Usage: hex2rgb(\$hex [,\$delim]";
    }


    $hex =~ s/^(\#|Ox)//;

    $_ = $hex;
    my ($r, $g, $b) = m/(\w{2})(\w{2})(\w{2})/;

    my @rgb = ();
    $rgb[0] = CORE::hex($r);
    $rgb[1] = CORE::hex($g);
    $rgb[2] = CORE::hex($b);

    defined $delim and return join ($delim, @rgb);

    return @rgb;
}



# rgb2hex(): opposite of hex2rgb().
# Usage: CLASS->rgb2hex($r, $g, $b [,'#'])
# RETURN VALUE: hex string
sub rgb2hex {
    my ($self, $r, $g, $b, $pound) = @_;

    unless ( defined $b ) {
        croak "Color::Rgb->rgb2hex(): Usage: rgb2hex(\$red, \$green, \$blue [,\$prefix]";
    }

    return sprintf("$pound%02lx%02lx%02lx", $r, $g, $b);
}



# names(): returns a list of names
# Usage: CLASS->names(['gray'])
# RETURN VALUE: list
sub names {
    my ($self, $pat) = @_;

    my @names = ();

    while ( my ($name, $rgb) = each %{$self->{_rgb_map}} ) {
        if ( defined $pat ) {
            $name =~ m/$pat/ and push (@names, $name);
            next;
        }
        push @names, $name;
    }

    return @names;
}


1;

###########################################################################
################ Color::Rgb manual follows ################################
###########################################################################

=pod

=head1 NAME

Color::Rgb - Simple rgb.txt parsing class

=head1 REVISION

$Revision: 1.4 $

=head1 SYNOPSIS

    use Color::Rgb;
    $rgb = new Color::Rgb(rgb_txt=>'/usr/X11R6/lib/X11/rgb.txt');

    @rgb = $rgb->rgb('red');            # returns 255, 0, 0
    $red = $rgb->rgb('red', ',');       # returns the above rgb list as
                                        # comma separated string
    $red_hex=$rgb->hex('red');          # returns 'FF0000'
    $red_hex=$rgb->hex('red', '#');     # returns '#FF0000'

    $my_hex = $rgb->rgb2hex(255,0,0);   # returns 'FF0000'
    $my_rgb = $rgb->hex2rgb('#FF0000'); # returns list of 255,0,0

=head1 DESCRIPTION

Color::Rgb - simple rgb.txt parsing class.

=head1 METHODS

=over 4

=item *

C<new([rgb_txt=>$rgb_file])> - constructor. Returns a Color::Rgb object.
Optionally accepts a path to the rgb.txt file. If you omit the file, it
will use the path in the $Color::Rgb::RGB_TXT variable, which defaults to
C<'/usr/X11R6/lib/X11/rgb.txt'>. It means, instead of using rgb_txt=>''
option, you could also set the value of the $Color::Rgb::RGB_TXT variable
to the correct path before you call the L<new()> constructor (but definitely
after you load the Color::Rgb class with C<use> or C<require>).

Note: If your system does not provide with any rgb.txt file, Color::Rgb
distribution includes one you can use instead.

=item *

C<name2rgb($name [,$delimiter])> - returns list of numeric Red, Green and Blue
values for a $name delimited (optionally) by a $delimiter . $name is
name of the color in the English language (Ex., 'black', 'red', 'purple' etc.).

Examples:

    my ($r, $g, $b) = $rgb->rgb('blue');      # returns list: 00, 00, 255
    my $string      = $rgb->rgb('blue', ','); # returns string: '00,00,255'

If name does not exist in the rgb.txt file it will return undef.

=item *

C<name2hex($name [,$prefix])> - similar to L<rgb($name)> method, but returns
hexadecimal string representing red, green and blue colors, prefixed
(optionally) with $prefix. If $name does not exist in the rgb.txt file
it will return undef.

=item *

C<hex($name, [,$delimiter])> - alias to C<name2hex()>

=item *

C<rgb($name, [,$delimiter])> - alias to C<name2rgb()>

=item *

C<rgb2hex($r, $g, $b [,$prefix])> - converts rgb value to hexadecimal string.
This method has nothing to do with the rgb.txt file, so none of the arguments
need to exist in the file.

Examples:

    @rgb = (128, 128, 128);               # RGB representation of grey
    $hex_grey = $rgb->rgb2hex(@rgb);      # returns string 'C0C0C0'
    $hex_grey = $rgb->rgb2hex(@rgb, '#'); # returns string '#C0C0C0'

=item *

C<hex2rgb('hex' [,$delim])> - the opposite of L<rgb2hex()>: takes a
hexadecimal representation of a color and returns a numeric list of Red,
Green and Blue. If optional $delim delimiter is present, it returns the
string of RGB colors delimited by the $delimiter. Characters like '#' and
'0x' in the beginning of the hexadecimal value will be ignored. Examples:

    $hex = '#00FF00';   # represents blue

    @rgb = $rgb->hex2rgb($hex);            #returns list of 0, 255, 0
    $rgb_string = $rgb->hex2rgb($hex,','); #returns string '0,255,0'

Note: L<hex2rgb()> expects valid hexadecimal representation of a color in
6 character long string. If not, it might not work properly.

=item *

C<names([$pattern]> - returns a list of all the names in the rgb.txt file.
If $pattern is given as the first argument, it will return only the names
matching the pattern. Example:

    @colors = $rgb->names;         # returns all the names

    @gray_colors = $rgb->names('gray'); # returns list of all the names
                                        # matching the word 'gray'
=back

=head1 CREDITS

Following people contributed to this library with their patches and/or
bug reports. (list is in chronological order)

=over 4

=item *

Marc-Olivier BERNARD <mob@kilargo.fr> notified of the warnings that the library
produced while "warnings" pragma enabled and improper parsed rgb values
that contain single "0". This bug was fixed in 1.2

=item *

Martin Herrmann <Martin-Herrmann@gmx.de> noticed a bug in rgb2hex() method which was 
failing if the blue value was a single "0". This problem is fixed in 1.3

=back

=head1 COPYRIGHT

Color::Rgb is a free software and can be modified and distributed under the same terms
as Perl itself. 

=head1 AUTHOR

Color::Rgb is maintained by Sherzod B. Ruzmetov <sherzodr@cpan.org>.

=head1 SEE ALSO

L<Color::Object>

=cut
