package Chart::Plotly::Image;

# ABSTRACT: Export static images of Plotly charts

use strict;
use warnings;

use utf8;

our $VERSION = '0.040';    # VERSION

use Chart::Plotly::Image::Orca;
use Chart::Plotly::Image::Orca::Client;
use Exporter qw(import);

our @EXPORT_OK = qw(save_image);

sub save_image {
    my %params = @_;
    my $engine = ( delete $params{engine} ) || 'auto';

    my @supported_engines = qw(kaleido orca);
    unless ( grep { $_ eq $engine } ( 'auto', @supported_engines ) ) {
        die "Unsupported engine: $engine";
    }

    if ( $params{orca_server} ) {
        _save_image_orca_client(%params);
    }

    if ( $engine eq 'auto' ) {
        for my $candidate (qw(kaleido orca)) {
            my $func_has = "_has_$candidate";
            no strict 'refs';    ## no critic
            if ( $func_has->() ) {
                $engine = $candidate;
                last;
            }
        }
    }
    if ( $engine eq 'auto' ) {
        die "None of @{[join(', ', @supported_engines)]} are available. "
          . "Please install Chart::Kaleido::Plotly (recommended) or Alien::Plotly::Orca. ";
    }
    my $func_save = "_save_image_$engine";
    no strict 'refs';            ## no critic
    return $func_save->(%params);
}

sub _has_kaleido {
    eval {
        require Chart::Kaleido::Plotly;
        Chart::Kaleido::Plotly->VERSION(0.005);
    };
    return !$@;
}

sub _has_orca {
    return Chart::Plotly::Image::Orca::orca_available;
}

sub _save_image_kaleido {
    my %params = @_;

    _has_kaleido();

    # Chart::Kaleido::Plotly's interface uses plotlyjs not plotly
    $params{plotlyjs} ||= delete $params{plotly};
    my %kaleido_params =
      map { exists $params{$_} ? ( $_ => delete $params{$_} ) : () } @{ Chart::Kaleido::Plotly->scope_flags };
    my $kaleido = Chart::Kaleido::Plotly->new(%kaleido_params);
    $kaleido->save(%params);
}

sub _save_image_orca {
    my %params = @_;

    Chart::Plotly::Image::Orca::orca(%params);
}

sub _save_image_orca_client {
    my %params = @_;

    $params{server} = delete $params{orca_server};
    Chart::Plotly::Image::Orca::Client::save_image(%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::Plotly::Image - Export static images of Plotly charts

=head1 VERSION

version 0.040

=head1 SYNOPSIS

    use Chart::Plotly::Plot;
    use Chart::Plotly::Trace::Scatter;
    use Chart::Plotly::Image qw(save_image);

    my $plot = Chart::Plotly::Plot->new(
        traces => [
            Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] )
        ]
    );
    save_image(file => 'TestOrca.png', plot => $plot,
               width => 1024, height => 768,
               engine => 'auto');

=head1 DESCRIPTION

This module generate static images of Plotly charts.

It internally uses either of below modules,

=over 4

=item *

L<Chart::Kaleido::Plotly>'s save() method.
Note that you will need to explicitly install L<Chart::Kaleido::Plotly>
for kaleido to work.

=item *

L<Chart::Plotly::Image::Orca>'s orca() function

=item *

L<Chart::Plotly::Image::Orca::Client>'s save_image() function

=back

=head1 FUNCTIONS

=head2 save_image

    save_image(file => $file, plot => $plot,
               width => $width, height => $height,
               engine => $engine,
               %rest)

Parameters

=over 4

=item * file

Image file path.

=item * engine

One of "auto", "kaleido", "orca".
Default is "auto", it tries in this order: kaleido, orca.

=item * orca_server

If this parameter is specified it will use L<Chart::Plotly::Image::Orca::Client>.

For example, 

    save_image(file => $file, plot => $plot,
               width => $width, height => $height,
               orca_server => 'http://localhost:9999')

=item * %rest

Rest parameters are passed through to the lower-level functions.

=back

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Chart-Plotly/issues>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

If you like plotly.js please consider supporting them purchasing a pro subscription: L<https://plot.ly/products/cloud/>

=head1 SEE ALSO

L<Chart::Kaleido::Plotly>,
L<Chart::Plotly::Image::Orca>,
L<Chart::Plotly::Image::Orca::Client>,

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
