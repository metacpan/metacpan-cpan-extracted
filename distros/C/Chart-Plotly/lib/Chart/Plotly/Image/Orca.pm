package Chart::Plotly::Image::Orca;

# ABSTRACT: Export static images of Plotly charts using orca

use 5.010;
use strict;
use warnings;

use Config;
use File::Which;
use Path::Tiny;
use File::ShareDir qw(dist_file);
use utf8;

our $VERSION = '0.027';    # VERSION

my $ORCA_COMMAND = 'orca';

# have this in a sub to avoid breaking auto-generated tests like pod-coverage.
sub _plotlyjs {
    state $plotlyjs = dist_file( 'Chart-Plotly', 'plotly.js/plotly.min.js' );
    return $plotlyjs;
}

sub _check_alien {
    my ($force_check) = @_;

    state $has_alien;

    if ( !defined $has_alien or $force_check ) {
        $has_alien = undef;
        eval { require Alien::Plotly::Orca; };
        if ( !$@ and Alien::Plotly::Orca->install_type eq 'share' ) {
            $ENV{PATH} = join( $Config{path_sep}, Alien::Plotly::Orca->bin_dir, $ENV{PATH} );
            $has_alien = 1;
        } else {
            $has_alien = 0;
        }
    }
    return $has_alien;
}

sub orca {
    my %params = @_;

    if ( orca_available() ) {
        my $plot   = $params{plot};
        my $file   = path( $params{file} );
        my $format = $params{format};
        unless ( defined $format ) {
            ($format) = $file =~ /\.([^\.]+)$/;
        }
        my $plotlyjs = $params{plotly} // _plotlyjs;

        my $tmp_json = Path::Tiny->tempfile( SUFFIX => '.json' );
        $tmp_json->spew_raw( $plot->TO_JSON );

        # For now have to explicitly specify -d as otherwise orca would
        #  not be able to store output to a different path other than cwd.
        # See https://github.com/plotly/orca/issues/101
        my @orca_line = ( $ORCA_COMMAND, 'graph', $tmp_json, '--plotlyjs', $plotlyjs, '-d', $file->parent,
                          '-o', $file->basename, ( $format ? ( '--format', $format ) : () )
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
    my ($force_check) = @_;

    state $available;

    if ( !defined $available or $force_check ) {
        $available = undef;
        if ( not _check_alien($force_check)
             and ( not which($ORCA_COMMAND) or not correct_orca() ) )
        {
            die "Orca tool (its 'orca' command) must be installed and in "
              . "PATH in order to export images. "
              . "Either install Alien::Plotly::Orca from CPAN, or install "
              . "it manually (see https://github.com/plotly/orca#installation)";
        }
        $available = 1;
    }
    return $available;
}

sub orca_version {
    my ($force_check) = @_;

    state $version;

    if ( _check_alien($force_check) ) {
        return Alien::Plotly::Orca->version;
    }
    if ( orca_available($force_check) ) {
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

version 0.027

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
using this module. You can either, 

=over 4

=item *

Install the L<Alien::Plotly::Orca> module from CPAN. Or,

=item *

Install plotly-orca yourself and have a C<orca> command findable via the
C<PATH> env var in your system, see also
L<https://github.com/plotly/orca#installation>.

=back

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

=head1 SEE ALSO

L<Alien::Plotly::Orca>

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
