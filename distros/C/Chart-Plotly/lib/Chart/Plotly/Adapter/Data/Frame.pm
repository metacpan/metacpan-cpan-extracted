package Chart::Plotly::Adapter::Data::Frame;

use strict;
use warnings;
use utf8;

use Moose;
use Chart::Plotly::Trace::Scatter;

extends 'Chart::Plotly::Adapter';

our $VERSION = '0.042';    # VERSION

sub traces {
    my $self       = shift();
    my $data_frame = $self->data;
    my $header     = $data_frame->column_names();
    my @traces;
    my $column_number = 0;
    for my $column (@$header) {
        push @traces,
          Chart::Plotly::Trace::Scatter->new( y    => $data_frame->nth_column( $column_number++ )->unpdl,
                                              name => $column );
    }
    return \@traces;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Adapter::Data::Frame

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use Data::Frame;
 use PDL;
 use Chart::Plotly qw(show_plot);
 
 my $df = Data::Frame->new( columns => [
     x => pdl(1, 2, 3, 4),
     y => ( sequence(4) * sequence(4)  ) ,
 ] );
 
 show_plot($df);

=head1 DESCRIPTION

Adapts Data::Frame objects to be plotted with Chart::Plotly

=head1 NAME

Chart::Plotly::Adapter::Data::Frame - Adapts Data::Frame to plot with Chart::Plotly

=head1 METHODS

=head2 traces

Returns the object/s Chart::Plotly::Trace::* ready to plot.

In this version every column is plotted as a line.

=head1 AUTHOR

Pablo Rodríguez González

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Chart-Plotly/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pablo Rodríguez González.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
