package Chart::Plotly::Image::Orca::Client;

# ABSTRACT: Export static images of Plotly charts using orca server

use 5.010;
use strict;
use warnings;

use Path::Tiny;
use LWP::UserAgent;
use utf8;

our $VERSION = '0.040';    # VERSION

sub save_image {
    my %params = @_;

    my $plot = $params{plot};
    my $file = path( $params{file} );

    my $ua = LWP::UserAgent->new;
    $ua->agent("Chart::Plotly::Image::Orca::Client/0.1");

    my $req = HTTP::Request->new( POST => $params{server} );
    $req->content_type('application/json');
    $req->content( $plot->to_json_text );
    my $res = $ua->request($req);
    if ( $res->is_success ) {
        path($file)->spew_raw( $res->content );
    } else {
        die "Can't export the plot. Server returned: " . $res->status_line;
    }
    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Image::Orca::Client - Export static images of Plotly charts using orca server

=head1 VERSION

version 0.040

=head1 SYNOPSIS

 #!/usr/bin/env perl 
 
 use strict;
 use warnings;
 use utf8;
 
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scatter;
 use Chart::Plotly::Image::Orca::Client;
 
 my $plot = Chart::Plotly::Plot->new(traces => [ Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] )]);
 
 Chart::Plotly::Image::Orca::Client::save_image(plot => $plot, file => "TestOrca.png", server => "http://[::]:9999");

=head1 DESCRIPTION

This module generate static images of Plotly charts without a browser using a
L<Orca|https://github.com/plotly/orca> server.

The server must be up and running before using this module. You can get an Orca server
using a docker image or just installing and running Orca yourself. There are some
instructions in L<Chart::Plotly::Image::Orca>

=head1 FUNCTIONS

=head2 save_image

    save_image(plot => $plot, file => "TestOrca.png", server => "http://[::]:9999");

Export L<Chart::Plotly::Plot> as a static image file.

=over 4

=item plot

Object to export

=item file

Filename (with or without path) to export

=item server

Url where the server is listening

=back

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

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
