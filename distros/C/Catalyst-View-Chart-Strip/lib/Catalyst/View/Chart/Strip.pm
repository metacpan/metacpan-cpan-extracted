package Catalyst::View::Chart::Strip;

use strict;
use base qw/Catalyst::View/;
use UNIVERSAL::require;
use Carp;
use NEXT;

our $VERSION = '0.05';

=head1 NAME

Catalyst::View::Chart::Strip - A Catalyst View for Chart::Strip graphics

=head1 SYNOPSIS

  package MyApp::View::ChartStrip;

  use strict;
  use base 'Catalyst::View::Chart::Strip';

  __PACKAGE__->config(
      cs_package => 'Chart::Strip',
      height => 192,
      width => 720,
      limit_factor => 1,
      transparent => 0,
      img_type => 'png',
      palette => [qw/
                     FF0000
                     00CC00
                     0000FF 
                     CC00CC 
                 /],
  );

  1;

  # A controller method which generates a chart:
  sub thechart : Local {
      my ( $self, $c ) = @_;

      [ ... generate $data and $opts somehow or other ... ]
      $c->stash->{chart_opts} = $opts;
      $c->stash->{chart_data} = $data;
      $c->forward('MyApp::View::ChartStrip');
  }

=head1 DESCRIPTION

This view allows the serving of Chart::Strip stripchart graphics
via Catalyst.  The raw numeric data and various chart options are
placed in C<$c-E<gt>stash>.

Instances of L<Catalyst::View::Chart::Strip>, like
C<MyApp::View::ChartStrip> shown in the synopsis above, can be thought
of as basically a collection of common defaults for the various chart
options.  You should probably create a seperate View class for each
distinct style of charts your application commonly generates.

All of the standard constructor arguments documented by L<Chart::Strip>
are supported as C<-E<gt>config> parameters in your View class, and are
also overrideable at chart generation time via
C<$c-E<gt>stash-E<gt>{chart_opts}>.

L<Catalyst::View::Chart::Strip> adds a few new options in addition to
the ones that are standard in L<Chart::Strip>, which are detailed below.

=head1 CONFIGURATION PARAMETERS

(See L<Chart::Strip> for a complete list of options.  Any L<Chart::Strip>
option can be passed through as a C<-E<gt>config> parameter).

All of these options are valid both a C<-E<gt>config> time, or at chart
generation time via C<$c-E<gt>stash-E<gt>{chart_opts}>.

=head2 img_type

Sets the output image type.  Values currently supported by L<Chart::Strip>
and L<GD> beneath it are C<png> and C<jpeg>.  The default is C<png> if
unspecified.

=head2 quality

This is the quality parameter for the output graphics data, as documented
in detail by L<GD>'s documentation.  Valid quality ranges are 0-100 for
C<jpeg> and 0-9 for C<png>.  Completely optional, and defaults to a
reasonably normal value in both cases.

=head2 palette

An optional arrayref of colors as six-digit hexidecimal strings, like
C<FFFFFF> or C<4A5C2D>.  The various datasets in your graph will be
colored with the colors of this array in order, recycling to the top
of the list if there are more data items than colors specified.  The default
is a reasonable 9-color high-contrast palette designed for a white
background, which happens to also be the default.

=head2 cs_package

This allows choosing an alternative but compatible C<Chart::Strip>
implementation, such as L<Chart::Strip::Stacked>.  Defaults to
the original L<Chart::Strip>.

=head1 STASH VARIABLES

As shown in the synopsis at the top, your chart is ultimately defined
by the contents of two stash variables: C<$c-E<gt>stash-E<gt>{chart_opts}>,
and C<$c-E<gt>stash-E<gt>{chart_data}>.

C<chart_opts> is analogous to the configuration options described above for
the View-wide C<-E<gt>config> settings.  Valid things here are all of the
documented arguments to L<Chart::Strip>'s C<new()> method, as well as
the configuration parameters specifically details above.

C<chart_data> should be an arrayref of sets of data to be charted.  Each
item in the arrayref should in turn be a hashref consisting of two keys:
C<data> and C<opts>.  These two keys are analogous to the two arguments
of L<Chart::Strip>'s C<add_data> method.

In other words, the following example standard L<Chart::Strip> code:

  my $chart = Chart::Strip‐>new( title   => 'Happiness of our Group' );
  $chart‐>add_data( $davey_data, { style => 'line',
                                   color => 'FF0000',
                                   label => 'Davey' } );

  $chart‐>add_data( $jenna_data, { style => 'line',
                                   color => '00FF88',
                                   label => 'Jenna' } );

Becomes this in terms of stash variables:

   $c->stash->{chart_opts}->{title} = 'Happiness of our Group';
   $c->stash->{chart_data} = [
       { data => $davey_data, opts => { style => 'line',
                                        color => 'FF0000',
                                        label => 'Davey'  }
       },
       { data => $jenna_data, opts => { style => 'line',
                                        color => '00FF88',
                                        label => 'Jenna'  }
       },

   ];

Note that colors are completely optional for us, since we have a reasonable
default palette.  You need only neccesarily supply the style and label options
for a reasonable chart.

See L<Catalyst::View::Chart::Strip::Example> for a full-fledged controller
action you can copy and paste as a working example.

=cut

# This default palette is hand-tweaked for contrast
# against white background on an RGB monitor for human eyes.
# The first 7 colors are very good, and the last 2 are decent
# enough for most purposes.  There is no perfect 9+ color
# high-constrast palette, and this is probably as good as it gets.

our $def_pal = [qw/
    FF0000
    00CC00
    0000FF 
    CC00CC 
    00BBDD 
    DDBB00
    000000
    666666
    557700
/];

=head1 METHODS

=head2 new

Constructor for these Views.  Mainly just defaults the above-documented
View-specific options, and loads the selected C<cs_package> package.

=cut

sub new {
    my $self = shift->NEXT::new(@_);

    $self->{cs_package} ||= 'Chart::Strip';
    $self->{img_type} ||= 'png';
    $self->{palette} ||= $def_pal;
    $self->{cs_package}->require
        or croak "Cannot load Chart::Strip module '$self->{cs_package}'";

    $self;
}

=head2 process

This does the chart generation itself.  The bulk of the code is
concerned with applying the palette to your data before constructing
the L<Chart::Strip> object and using it to generate the output
binary image data.

=cut

sub process {
    my ($self, $c) = @_;

    my $opts = $c->stash->{chart_opts};
    my $data = $c->stash->{chart_data};

    my $chart   = $self->{cs_package}->new( %$self, %$opts );
    my $palette = $chart->{palette};

    # This is all in support of defaulted color palettes
    my $is_stacked = ($data->[0]->{opts}->{style} eq 'stacked');
    if($is_stacked) {
        my $stack = $data->[0];
        if( ! @{ $stack->{opts}->{colors} || [] } ) {
            my @stacked_colors;
            my $cnum = 0;
            my $ncolors_wanted = @{$stack->{data}->[0]->{values}};
            foreach (1..$ncolors_wanted) {
                unshift(@stacked_colors, $palette->[$cnum]);
                $cnum++;
                $cnum = 0 if $cnum > $#$palette;
            }
            $stack->{opts}->{colors} = \@stacked_colors;
            $chart->add_data($stack->{data}, $stack->{opts});
        }
    }
    else {
        my $cnum = 0;
        foreach (@$data) {
            $_->{opts}->{color} ||= $palette->[$cnum];
            $chart->add_data($_->{data}, $_->{opts});
            $cnum++;
            $cnum = 0 if $cnum > $#$palette;
        }
    }

    my $itype = $chart->{img_type};
    $c->response->content_type("image/$itype");
    $c->response->body($chart->$itype($chart->{quality}));
}

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::Helper::View::Chart::Strip>,
L<Catalyst::View::Chart::Strip::Example>, L<Chart::Strip>,
L<Chart::Strip::Stacked>

=head1 AUTHOR

Brandon L Black, C<blblack@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
