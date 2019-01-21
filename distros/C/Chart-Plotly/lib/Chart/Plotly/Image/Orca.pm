package Chart::Plotly::Image::Orca;

# ABSTRACT: Export static images of Plotly charts using orca

use strict;
use warnings;

use File::Which;
use Path::Tiny;
use utf8;

our $VERSION = '0.023';    # VERSION

my $ORCA_COMMAND = 'orca';

sub orca {
    my %params = @_;

    if ( orca_available() ) {
        my $plot   = $params{plot};
        my $file   = path( $params{file} );
        my $format = $params{format};
        unless ( defined $format ) {
            ($format) = $file =~ /\.([^\.]+)$/;
        }

        my $tmp_json = Path::Tiny->tempfile( SUFFIX => '.json' );
        $tmp_json->spew_raw( $plot->TO_JSON );

        # For now have to explicitly specify -d as otherwise orca would
        #  not be able to store output to a different path other than cwd.
        # See https://github.com/plotly/orca/issues/101
        my @orca_line = ( $ORCA_COMMAND, 'graph', $tmp_json, '-d', $file->parent, '-o', $file->basename,
                          ( $format ? ( '--format', $format ) : () )
        );
        for my $arg (qw(mathjax scale width height)) {
            if ( my $val = $params{$arg} ) {
                push @orca_line, ( "--${arg}", $val );
            }
        }
        for my $arg (qw(safe verbose debug)) {
            if ( $params{$arg} ) {
                push @orca_line, "--${arg}";
            }
        }

        #my $orca_line = join(" ", @orca_line);
        my $rc = system(@orca_line);
        return 1 unless ( $rc >> 8 );
    }
    return;
}

sub correct_orca {
    my $orca_help = `$ORCA_COMMAND -h`;
    return ( $orca_help =~ /plotly/i );
}

sub orca_available {
    if ( not which($ORCA_COMMAND) or not correct_orca() ) {
        die "Orca tool must be installed and in PATH in order to export images. "
          . "See also https://github.com/plotly/orca#installation";
    }
    return 1;
}

sub orca_version {
    if ( orca_available() ) {
        my $version = `$ORCA_COMMAND --version`;
        chomp($version);
        return $version;
    }
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Image::Orca - Export static images of Plotly charts using orca

=head1 VERSION

version 0.023

=head1 SYNOPSIS

 #!/usr/bin/env perl 
 
 use strict;
 use warnings;
 use utf8;
 
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scatter;
 use Chart::Plotly::Image::Orca;
 
 my $plot = Chart::Plotly::Plot->new(traces => [ Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] )]);
 
 Chart::Plotly::Image::Orca::orca(plot => $plot, file => "TestOrca.png");

=head1 DESCRIPTION

This module generate static images of Plotly charts without a browser using
L<Orca|https://github.com/plotly/orca>

Orca is an L<Electron|https://electronjs.org/> app that must be installed before
using this module. See L<https://github.com/plotly/orca#installation>

=head1 FUNCTIONS

=head2 orca

    orca(plot => $plot, file => $file, %rest)

Export L<Chart::Plotly::Plot> as a static image file.

This function is a wrapper over the plotly orca command.
Most of its named parameters are mapped to orca's command line options.
See also the output of C<orca graph --help>.

Returns a true value if the orca command is successful.

=over 4

=item plot

Object to export

=item file

Filename (with or without path) to export

=item format

Sets the output format (png, jpeg, webp, svg, pdf, eps).
By default it's inferred from the specified file name extension.

=item scale

Sets the image scale.

=item width

Sets the image width.

=item height

Sets the image height.

=item mathjax

Sets path to MathJax files. Required to export LaTeX characters.

=item safe

Turns on safe mode: where figures likely to make browser window hang
during image generating are skipped.

=item verbose

Turn on verbose logging on stdout.

=item debug

Starts app in debug mode and turn on verbose logs on stdout.

=back

=head2 correct_orca

Checks that orca command available is the plotly image exporter,
as there may be some other different command also named "orca", like
L<https://help.gnome.org/users/orca/stable/>

=head2 orca_available

Checks that orca command is available and the plotly image exporter

=head2 orca_version

Returns the orca version

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Chart-Plotly/issues>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

If you like plotly.js please consider supporting them purchasing a pro subscription: L<https://plot.ly/products/cloud/>

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
