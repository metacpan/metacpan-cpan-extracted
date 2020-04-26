package Astro::DSS::JPEG;

use 5.006;
use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use List::Util 'min';

=encoding utf8

=head1 NAME

Astro::DSS::JPEG - Download color JPEG images from the Digitized Sky Survey

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Astro::DSS::JPEG;

    my $dss = Astro::DSS::JPEG->new();

    #get an object (Triangulum galaxy M33) by name at default 1000x1000,
    #getting coordinates and frame size automatically from SIMBAD
    my $image = $dss->get_image(target => 'M33');

    #Save an image directly to file manually specifying coordinates, frame of 
    #90x90 arcmin, 2048x2048 pixels
    $dss->get_image(
        ra           => '01 33 50.904',
        dec          => '+30 39 35.79',
        angular_size => 90,
        pixel_size   => 2048,
        filename     => $filename
    );

    #In one go, save Andromeda Galaxy to andromeda.jpg
    Astro::DSS::JPEG->new->get_image(target=>'Andromeda Galaxy', filename=>'andromeda.jpg');

=head1 DESCRIPTION

Astro::DSS::JPEG downloads JPEG images for any location in the sky from the L<Digitized Sky Survey (DSS)|https://archive.stsci.edu/dss/>.
It is meant to be a simple stand alone module to access a fast JPEG-only API that
provides color composites made from the blue and red DSS surveys.
In comparison, there is an old/not updated L<Astro::DSS> module that would provide
access to the slow FITS/GIF interface of the separate DSS1/DSS2 surveys.

Optionally, L<SIMBAD|http://simbad.u-strasbg.fr/simbad/> is used if you'd like to use
an object name/id instead of coordinates.

=head1 CONSTRUCTOR METHODS

=head2 C<new>

    my $dss = Astro::DSS::JPEG->new(
        dss_url    => 'http://gsss.stsci.edu/webservices/dssjpg/dss.svc/GetImage', # Optional
        simbad_url => 'http://simbad.u-strasbg.fr/simbad/sim-id',                  # Optional
        ua         => $ua                                                          # Optional
    );
  
All parameters are optional. The constructor by default creates an L<LWP::UserAgent>,
but you can pass your own with C<ua>, while the URL to the L<STScI|https://archive.stsci.edu/dss/copyright.html>
JPEG endpoint and the L<SIMBAD|http://simbad.u-strasbg.fr/simbad/> simple identifier query
interface can be redefined (e.g. if they change in the future) from the above shown defaults.

=head1 METHODS

=head2 C<get_image>

    my $res = $dss->get_image(
        target       => $target,            # Not used if RA, Dec provided
        ra           => $ra,                # Right Ascension (in hours of angle)
        dec          => $dec,               # Declination (in degrees of angle)
        angular_size => 30,                 # Optional. Frame angular size in arcmin
        pixel_size   => 1000,               # Optional. Frame size in pixels
        filename     => $filename           # Optional. Filename to save image to
    );

Fetches an image either resolving the name through L<SIMBAD|http://simbad.u-strasbg.fr/simbad/>,
or using RA & Dec when they are defined. If you pass a C<filename>, the JPEG image will
be saved to that and the function will return an L<HTTP::Response> object, otherwise the
image data will be returned as a response. 

The parameters to pass:

=over 4
 
=item * C<ra>

Right ascension, from 0-24h of angle. The option is flexible, it will accept a single
decimal number - e.g. C<2.5> or a string with hours, minutes, secs like C<'2 30 00'> or
C<'2h30m30s'> etc. Single/double quotes and single/double prime symbols are accepted
for denoting minute, second in place of a single space which also works.

=item * C<dec>

Declination, from -90 to 90 degrees of angle. The option is flexible, it will accept
a single decimal number - e.g. C<54.5> or a string with degrees, minutes, secs like
C<'+54 30 00'> or C<'54°30m30s'> etc. Single/double quotes and single/double prime symbols
are accepted for denoting minute, second in place of a single space which also works.

=item * C<target>

Do a L<SIMBAD|http://simbad.u-strasbg.fr/simbad/> lookup to get the C<target> by name
(e.g. 'NGC598'). Will be disregarded if C<ra> and C<dec> are defined. If you have not
defined an C<angular_size> and L<SIMBAD|http://simbad.u-strasbg.fr/simbad/> has one
defined, it will be used for the image request with an extra 50% for padding.

=item * C<angular_size>

Define the frame angular size in arcminutes, either as a single number (square) or
a comma separated string for a rectangle. Default is 0.5 degrees (equivalent to passing
C<30> or C<'30,30'> or even C<'30x30'>). The aspect ratio will be overriden by C<pixel_size>.
If you care about framing, you should definitely define C<angular_size>, as the default
won't be appropriate for many targets and L<SIMBAD|http://simbad.u-strasbg.fr/simbad/> often
does not have the info (or even has an inappropriate value). Also, large C<angular_size>
values can make the response slow (or even error out).

=item * C<pixel_size>

Define the frame size in pixels, either as a single number (square) or a comma separated
string for a rectangle. Default is 1000 pixels (equivalent to passing C<1000> or
C<'1000,1000'> or even C<'1000x1000'>). Max possible is C<'4096,4096'> total size,
or 1 pixel / arcsecond resolution (e.g. 30*60 = 1800 pixels for 30 arcminutes), which
is the full resolution DSS plates were scanned at.

=back

=head1 NOTES

Some artifacts can be seen at the borders of separate "stripes" of the survey and
also the particular JPEG endpoint used sometimes can leave the corners as plain black
squares (depending on the selected frame size, as it is to do with the way it does
segmentation), so if you want to make sure you have a frame with no corner gaps,
request some more angular size than you want and crop. 

Note that the module test suite won't actually fetch data from either DSS or SIMBAD.
This is mainly to ensure it will not fail even if the DSS & SIMBAD endpoints change,
as you can still use the module by passing the updated urls to the constructor. It
also avoids unneeded strain to those free services.

=cut


sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless($self, $class);

    $self->{dss_url} = $opts{dss_url}
      || 'http://gsss.stsci.edu/webservices/dssjpg/dss.svc/GetImage';
    $self->{simbad_url} = $opts{simbad_url}
      || 'http://simbad.u-strasbg.fr/simbad/sim-id';
    $self->{ua} = $opts{ua}
      || LWP::UserAgent->new(
        agent => "perl/Astro::DSS::JPEG/$VERSION",
      );

    return $self;
}

sub get_image {
    my ($self, %opts) = @_;
    if ($opts{target} && (! defined $opts{ra} || ! defined $opts{dec})) {
        my $simbad = $self->_get_simbad(%opts);
        %opts = (
            %opts,
            %$simbad
        );
    }

    my $res = $self->_get_dss(_process_options(%opts));
    if ($res->is_success) {
        return $res if $opts{filename};
        return $res->decoded_content;
    } else {
        die "*ERROR* Could not access DSS at: ".$res->request->uri
            ."\nHTTP Response:\n".$res->status_line;
    }
}

sub _get_dss {
    my ($self, %opts) = @_;

    my @request = (
        $self->{dss_url} . sprintf(
            "?POS=%f,%f&SIZE=%f,%f&ISIZE=%.0f,%.0f",
            $opts{ra} * 15,             # Convert to degrees
            $opts{dec},
            $opts{angular_size} / 60,   # Convert to degrees
            $opts{angular_size_y} / 60, # Convert to degrees
            $opts{pixel_size},
            $opts{pixel_size_y}
        )
    );
    push @request, (':content_file' => $opts{filename}) if $opts{filename};
    return $self->{ua}->get(@request);
}

sub _convert_coordinates {
    my %opts = @_;
    if (defined $opts{ra} && $opts{ra} =~ /([+-]?[0-9.]+)[ h]+([0-9.]+)[ m′']+([0-9.]+)/) {
        $opts{ra} = $1+$2/60+$3/3600;
    }
    if (defined $opts{dec} && $opts{dec} =~ /([+-]?[0-9.]+)[ d°]+([0-9.]+)[ m′']+([0-9.]+)/) {
        my $sign = $1 < 0 ? -1 : 1;
        $opts{dec} = (abs($1)+$2/60+$3/3600)*$sign;
    }
    return %opts;
}

sub _process_options {
    my %opts = _convert_coordinates(@_);
    $opts{angular_size} ||= 30; # 30' Default angular size
    $opts{pixel_size}   ||= 1000;

    if ($opts{angular_size} =~ /(\S+)\s*[,xX]\s*(\S+)/) {
        $opts{angular_size}   = $1 || 30;
        $opts{angular_size_y} = $2;
    }
    if ($opts{pixel_size} =~ /(\S+)\s*[,xX]\s*(\S+)/) {
        $opts{pixel_size}   = $1 || 1000;
        $opts{pixel_size_y} = $2;
    }

    $opts{angular_size_y} = $opts{angular_size} unless $opts{angular_size_y};
    $opts{pixel_size_y}   = $opts{pixel_size}*$opts{angular_size_y}/$opts{angular_size}
        unless $opts{pixel_size_y};

    $opts{"pixel$_"} = min 4096, $opts{"pixel$_"}, $opts{"angular$_"}*60
        for qw/_size _size_y/;

    return %opts;
}

sub _get_simbad {
    my ($self, %opts) = @_;

    my $res = $self->{ua}->get(
        $self->{simbad_url}."?output.format=ASCII&Ident=".$opts{target}
    );
    if ($res->is_success) {
        my $simbad = $res->decoded_content;
        if ($simbad =~ /\(ICRS,ep=J2000,eq=2000\): (\S+ \S+ \S+)\s+(\S+ \S+ \S+)/) {
            $opts{ra}  = $1;
            $opts{dec} = $2;
        } else {
            die "*ERROR* Could not parse SIMBAD output:\n$simbad";
        }
        if ($simbad =~ /Angular size:\s*([0-9.]+)/) { # Get only largest dimension
            $opts{angular_size} = min($1 * 1.5, 600); # Get 50% extra for framing, max out at 10 degrees
        }
    } else {
        die "*ERROR* Could not access SIMBAD at: "
            .$self->{simbad_url}."?output.format=ASCII&Ident=".$opts{target}
            ."\nHTTP response:\n".$res->status_line;
    }

    return \%opts;
}

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-astro-dss-jpeg at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-DSS-JPEG>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

You could also submit issues or even pull requests to the
github repo (see below).


=head1 GIT

L<https://github.com/dkechag/Astro-DSS-JPEG>


=head1 ACKNOWLEDGEMENTS

The DSS images are downloaded using a public api of the L<Digitized Sky Survey|https://archive.stsci.edu/dss/>
provided by the L<Space Telescope Science Institute|http://www.stsci.edu>.

Targets by name/id are resolved using the L<SIMBAD Astronomical Database|http://simbad.u-strasbg.fr/simbad/>.


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

For the images you download with this module, please see the L<STScI site|https://archive.stsci.edu/dss/copyright.html>
for the full copyright info.


=cut

1;
