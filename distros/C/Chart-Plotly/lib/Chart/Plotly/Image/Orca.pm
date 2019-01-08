package Chart::Plotly::Image::Orca;

use Moose;
use File::Which;
use Path::Tiny;
use utf8;

our $VERSION = '0.022';    # VERSION

my $ORCA_COMMAND = 'orca';

sub orca {
    my %params = @_;

    if ( orca_available() ) {
        my $plot = $params{plot};
        my $file = path( $params{file} );

        my $tmp_json = Path::Tiny->tempfile( SUFFIX => '.json' );
        $tmp_json->spew_raw( $plot->TO_JSON );

        # For now have to explicitly specify -d as otherwise orca would
        #  not be able to store output to a different path other than cwd.
        # See https://github.com/plotly/orca/issues/101
        my @orca_line = ( $ORCA_COMMAND, 'graph', $tmp_json, '-d', $file->parent, '-o', $file->basename );
        my $orca_line = join( " ", @orca_line );

        system($orca_line);
    }
}

sub correct_orca {
    my $orca_help = `$ORCA_COMMAND -h`;
    return ( $orca_help =~ /plotly/i );
}

sub orca_available {
    if ( not which($ORCA_COMMAND) or not correct_orca() ) {
        die "Orca tool must be installed and in PATH in order to export images";
    }
    return 1;
}

sub orca_version {
    my $version = `$ORCA_COMMAND --version`;
    chomp($version);
    return $version;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Image::Orca

=head1 VERSION

version 0.022

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

# ABSTRACT: Export static images of Plotly charts using orca

=head1 FUNCTIONS

=head2 orca

Export L<Chart::Plotly::Plot> as a static image file

=over 4

=item plot

Object to export

=item file

Filename (with or without path) to export

=back

=head2 correct_orca

Checks that orca command available is the plotly image exporter

=head2 orca_available

Checks that orca command is available and the plotly image exporter

=head2 orca_version

Returns the orca version

=head1 AUTHOR

Pablo Rodríguez González

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Chart-Plotly/issues>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

If you like plotly.js please consider supporting them purchasing a pro subscription: L<https://plot.ly/products/cloud/>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Pablo Rodríguez González.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
