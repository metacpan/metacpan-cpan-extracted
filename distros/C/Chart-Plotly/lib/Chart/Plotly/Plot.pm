package Chart::Plotly::Plot;

use Moose;
use utf8;

use UUID::Tiny ':std';

our $VERSION = '0.012';    # VERSION

use Chart::Plotly;

has traces => ( traits  => ['Array'],
                is      => 'rw',
                isa     => 'ArrayRef',
                default => sub { [] },
                handles => { add_trace    => 'push',
                             get_trace    => 'get',
                             insert_trace => 'insert',
                             delete_trace => 'delete'
                }
);

has layout => ( is  => 'rw',
                isa => 'HashRef' );

sub html {
    my $self     = shift;
    my %params   = @_;
    my $chart_id = $params{'div_id'} // create_uuid_as_string(UUID_TIME);
    my $layout   = $self->layout;
    if ( defined $layout ) {
        $layout = Chart::Plotly::_process_data($layout);
    }
    return Chart::Plotly::_render_cell( Chart::Plotly::_process_data( $self->traces() ), $chart_id, $layout );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Plot

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use Chart::Plotly::Trace::Scatter;
 use Chart::Plotly::Plot;
 use HTML::Show;
 
 my $x = [1 .. 15];
 my $y = [map {rand 10 } @$x];
 my $scatter = Chart::Plotly::Trace::Scatter->new(x => $x, y => $y);
 my $plot = Chart::Plotly::Plot->new();
 $plot->add_trace($scatter);
 
 HTML::Show::show($plot->html);
 
 # This also works
 # HTML::Show::show(Chart::Plotly::render_full_html(data => $plot));

=head1 DESCRIPTION

Represent a full plot composed of one or more traces (Chart::Plotly::Trace::*)

=head1 NAME

Chart::Plotly::Plot - Set of traces with their options and data

=head1 METHODS

=head2 html

Returns the html corresponding to the plot

=head3 Parameters

=head1 AUTHOR

Pablo Rodríguez González

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Chart-Plotly/issues>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

If you like plotly.js please consider supporting them purchasing a pro subscription: L<https://plot.ly/products/cloud/>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pablo Rodríguez González.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
