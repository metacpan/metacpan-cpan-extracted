package Chart::Plotly::Adapter::Data::Table;

use strict;
use warnings;
use utf8;

use Moose;
use Chart::Plotly::Trace::Scatter;

extends 'Chart::Plotly::Adapter';

our $VERSION = '0.027';    # VERSION

has options => ( is  => 'ro',
                 isa => 'HashRef' );

sub traces {
    my $self   = shift();
    my $table  = $self->data();
    my @header = $table->header();
    my @traces;
    for my $column (@header) {
        push @traces,
          Chart::Plotly::Trace::Scatter->new( y    => [ $table->col($column) ],
                                              name => $column );
    }
    return \@traces;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Adapter::Data::Table

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Data::Table;
 use HTML::Show;
 use Chart::Plotly;
 
 my $table = Data::Table::fromFile('morley.csv');
 
 HTML::Show::show(
 	Chart::Plotly::render_full_html(
 		data => $table, 
 	)); # Automatic dispatch

=head1 DESCRIPTION

Adapts Data::Table objects to be plotted with Chart::Plotly

=head1 NAME

Chart::Plotly::Adapter::Data::Table - Adapts Data::Table to plot with Chart::Plotly

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

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
