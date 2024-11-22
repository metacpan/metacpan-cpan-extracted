package Chart::ECharts::Base;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp ();
use base 'Chart::ECharts';

sub type { Carp::croak 'Unknown chart type' }

sub default_options { {tooltip => {trigger => 'axis'}} }

sub build_series {

    my ($self, $data) = @_;

    if (ref($data) eq 'HASH') {
        $data = [map { {name => $_, value => $data->{$_}} } sort keys %{$data}];
    }

    return {type => $self->type, data => $data};

}

sub category {

    my ($self, $data) = @_;

    $self->add_xAxis(type => 'category', data => $data);
    $self->add_yAxis(type => 'value');

}

sub data {

    my ($self, @args) = @_;

    my ($name, $data, $options) = @args;
    $options //= {};

    my $series = $self->build_series($data);

    $series->{name} = $name;
    $series = {%{$series}, %{$options}};

    $self->add_series(%{$series});
    return $self;

}

1;

__END__

=encoding utf-8

=head1 NAME

Chart::ECharts::Base - Base class helper

=head1 SYNOPSIS

    use Chart::Echarts::Bar;

    my $chart = Chart::ECharts::Bar->new;

    $chart->category(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    $chart->data('week 1' => [120, 200, 150, 80,  70, 110, 130]);
    $chart->data('week 2' => [90,  100, 120, 120, 60, 150, 110]);

    $chart->render_html;


=head1 DESCRIPTION

L<Chart::ECharts::Base> is a base class for chart helpers:

=over

=item L<Chart::ECharts::Bar>

=item L<Chart::ECharts::Candlestick>

=item L<Chart::ECharts::Donut>

=item L<Chart::ECharts::Gauge>

=item L<Chart::ECharts::Line>

=item L<Chart::ECharts::Parallel>

=item L<Chart::ECharts::Pie>

=item L<Chart::ECharts::Radar>

=item L<Chart::ECharts::Scatter>

=item L<Chart::ECharts::StackedBar>

=back

=head2 METHODS

L<Chart::ECharts::Base> inherits all methods from L<Chart::ECharts>
and implements the following new ones.

=over

=item $chart->data

=item $chart->build_series

=item $chart->category

=back

=head2 PROPERTIES

=over

=item $chart->type

Chart type

=item $chart->default_options

Default chart options

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Chart-ECharts/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Chart-ECharts>

    git clone https://github.com/giterlizzi/perl-Chart-ECharts.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
