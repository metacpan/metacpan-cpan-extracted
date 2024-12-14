package Chart::ECharts;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use JSON::PP       ();
use Digest::SHA    qw(sha1_hex);
use File::ShareDir qw(dist_file);
use File::Spec;
use IPC::Open3;
use File::Basename;

our $VERSION = '1.02';
$VERSION =~ tr/_//d;    ## no critic

use constant DEBUG => $ENV{ECHARTS_DEBUG} || 0;

sub new {

    my $class = shift;

    my %params = (
        charts_object    => 'ChartECharts',
        class            => 'chart-container',
        container_prefix => '',
        events           => {},
        scripts          => [],
        height           => undef,
        id               => ('chart_' . get_random_id()),
        locale           => 'en',
        options          => {},
        renderer         => 'canvas',
        responsive       => 0,
        series           => [],
        styles           => ['min-width:auto', 'min-height:300px'],
        theme            => 'white',
        vertical         => 0,
        width            => undef,
        xAxis            => [],
        yAxis            => [],
        @_
    );

    my $self = {%params};

    $self->{js} = {};

    return bless $self, $class;

}

sub chart_id { shift->{id} }

sub set_options {
    my ($self, %options) = @_;
    $self->{options} = {%{$self->{options}}, %options};
}

sub set_option {
    Carp::carp 'DEPRECATED use $chart->set_options(%params)';
    shift->set_options(@_);
}

sub set_option_item {
    my ($self, $name, $params) = @_;
    $self->{options}->{$name} = $params;
}

sub set_title {
    my ($self, %params) = @_;
    $self->set_option(title => \%params);
}

sub set_tooltip {
    my ($self, %params) = @_;
    $self->set_option(tooltip => \%params);
}

sub set_toolbox {
    my ($self, %params) = @_;
    $self->set_option(toolbox => \%params);
}

sub set_legend {
    my ($self, %params) = @_;
    $self->set_option(legend => \%params);
}

sub set_timeline {
    my ($self, %params) = @_;
    $self->set_option(timeline => \%params);
}

sub set_data_zoom {
    my ($self, %params) = @_;
    $self->set_option(dataZoom => \%params);
}

sub add_data_zoom {

    my ($self, %params) = @_;

    $self->{options}->{dataZoom} //= [];
    push @{$self->{options}}, \%params;

}

sub get_random_id {
    return sha1_hex(join('', time, rand));
}

sub set_event {
    my ($self, $event, $callback) = @_;
    $self->{events}->{$event} = $callback;
}

sub add_script {
    my ($self, $script) = @_;
    push @{$self->{scripts}}, $script;
}

sub on { shift->set_event(@_) }

sub set_xAxis {
    my ($self, %axis) = @_;
    $self->{xAxis} = \%axis;
}

sub add_xAxis {
    my ($self, %axis) = @_;
    push @{$self->{xAxis}}, \%axis;
}

sub set_yAxis {
    my ($self, %axis) = @_;
    $self->{yAxis} = \%axis;
}

sub add_yAxis {
    my ($self, %axis) = @_;
    push @{$self->{yAxis}}, \%axis;
}

sub add_series {
    my ($self, %series) = @_;
    push @{$self->{series}}, \%series;
}

sub xAxis  { shift->{xAxis} }
sub yAxis  { shift->{yAxis} }
sub series { shift->{series} }

sub default_options { {} }

sub options {

    my ($self) = @_;

    my $default_options = $self->default_options;
    my $global_options  = $self->{options};

    my $default_series_options = delete $default_options->{series} || {};
    my $series_options         = delete $global_options->{series}  || {};

    my $options = {series => $self->series};

    for (my $i = 0; $i < @{$options->{series}}; $i++) {
        $options->{series}->[$i] = {%{$options->{series}->[$i]}, %{$default_series_options}};
        $options->{series}->[$i] = {%{$options->{series}->[$i]}, %{$series_options}};
    }

    $options = {%{$options}, %{$self->axies}, %{$default_options}, %{$global_options}};

    return $options;

}

sub axies {

    my ($self) = @_;

    if ($self->{vertical}) {
        return {xAxis => $self->yAxis, yAxis => $self->xAxis};
    }

    return {xAxis => $self->xAxis, yAxis => $self->yAxis};

}

sub render_script {

    my ($self, %params) = @_;

    my $chart_id      = $self->{id};
    my $charts_object = $self->{charts_object};
    my $theme         = $self->{theme};
    my $renderer      = $self->{renderer};
    my $locale        = $self->{locale};
    my $container     = join '', $self->{container_prefix}, $chart_id;

    my $wrap = $params{wrap} //= 0;

    if ($chart_id !~ /^[a-zA-Z0-9_-]*$/) {
        Carp::croak 'Malformed chart "id" name';
    }

    if ($charts_object !~ /^[a-zA-Z0-9_-]*$/) {
        Carp::croak 'Malformed "charts_object" name';
    }

    my $json = JSON::PP->new;

    $json->utf8->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed->escape_slash(0);

    my $option = $json->encode($self->options);

    foreach my $identifier (keys %{$self->{js}}) {

        my $search  = qr/"\{JS:$identifier\}"/;
        my $replace = $self->{js}->{$identifier};

        $option =~ s/$search/$replace/;

    }

    my @script = ();

    my $init_options = $json->encode({locale => $locale, renderer => $renderer});

    push @script, '(function () {';

    # Add "charts_object"
    push @script, qq{\tif (!window.$charts_object) { window.$charts_object = {} }};
    push @script, qq{\tif (!window.$charts_object.charts) { window.$charts_object.charts = {} }};

    push @script, qq{\tlet chart = echarts.init(document.getElementById('$container'), '$theme', $init_options);};

    foreach my $script (@{$self->{scripts}}) {
        push @script, "\t$script";
    }

    push @script, qq{\tlet option = $option;};
    push @script, qq{\toption && chart.setOption(option);};

    foreach my $event (keys %{$self->{events}}) {
        my $callback = $self->{events}->{$event};
        push @script, qq{\tchart.on('$event', function (params) { $callback });};
    }

    push @script, qq{\twindow.$charts_object.charts["$chart_id"] = chart;};

    if ($self->{responsive}) {
        push @script, qq{\twindow.addEventListener('resize', function () { chart.resize() });};
    }

    push @script, '})();';

    my $script = join "\n", @script;

    return "<script>\n$script\n</script>" if $wrap;

    return $script;

}

sub render_html {

    my ($self) = @_;

    my $style  = '';
    my @styles = @{$self->{styles}};

    push @styles, sprintf('width:%s',  $self->{width})  if ($self->{width});
    push @styles, sprintf('height:%s', $self->{height}) if ($self->{height});

    my $script = $self->render_script(wrap => 1);

    my $chart_id        = $self->{id};
    my $container_id    = join '',  $self->{container_prefix}, $chart_id;
    my $styles          = join ';', @styles, $style;
    my $class_container = $self->{class};

    my $html = qq{<div id="$container_id" class="$class_container" style="$styles"></div>\n$script};

    return $html;

}

sub render_image {

    my ($self, %params) = @_;

    my $render_script = dist_file('Chart-ECharts', 'render.cjs');

    my $node_path = delete $params{node_path};
    my $node_bin  = delete $params{node_bin} || '/usr/bin/node';
    my $output    = delete $params{output}   || Carp::croak 'Specify "output" file';
    my $format    = delete $params{format};
    my $width     = delete $params{width};
    my $height    = delete $params{height};
    my $option    = JSON::PP->new->encode($self->options);

    if (!$format) {

        my ($file, $dir, $suffix) = fileparse($output, ('.png', ',svg'));

        Carp::croak 'Unsupported output "format"' unless $suffix;

        ($format = $suffix) =~ s/\.//;

    }

    if ($format ne 'png' && $format ne 'svg') {
        Carp::croak 'Unknown output "format"';
    }

    if ($node_bin !~ /(node|node.exe)$/i) {
        Carp::croak 'Unknown node command';
    }

    if (!-e $node_bin && !-x _) {
        Carp::croak 'Node binary not found';
    }

    local $ENV{NODE_PATH} //= $node_path if $node_path;

    my @cmd = ($node_bin, $render_script, '--output', $output, '--format', $format, '--option', $option);

    push @cmd, '--width',  $width  if ($width);
    push @cmd, '--height', $height if ($height);

    DEBUG and say STDERR sprintf('Command: %s', join ' ', @cmd);

    my $pid = open3(my $stdin, my $stdout, my $stderr, @cmd);

    waitpid($pid, 0);
    my $exit_status = $? >> 8;

    if (DEBUG) {

        say STDERR "Enviroment Variables:";
        say STDERR sprintf("NODE_PATH=%s\n", $ENV{NODE_PATH} || '');

        if ($stderr) {
            say STDERR 'Command STDERR:';
            say STDERR <$stderr>;
        }

        if ($stdout) {
            say STDERR 'Command STDOUT:';
            say STDERR <$stdout>;
        }

        say STDERR "Command exit status: $exit_status";

    }


}

sub js {

    my ($self, $expression) = @_;

    my $identifier = sha1_hex($expression);
    $self->{js}->{$identifier} = $expression;

    return "{JS:$identifier}";

}

sub TO_JSON { shift->options }


1;

__END__

=encoding utf-8

=head1 NAME

Chart::ECharts - Apache ECharts wrapper for Perl

=head1 SYNOPSIS

    use Chart::ECharts;

    my $chart = Chart::ECharts->new( responsive => 1 );

    $chart->add_xAxis(
        type => 'category',
        data => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    );

    $chart->add_yAxis(type => 'value');

    $chart->add_series(
        name => 'series_name',
        type => 'bar',
        data => [120, 200, 150, 80, 70, 110, 130]
    );

    # Render in HTML
    say $chart->render_html;

    # Render chart image (require Node.js)
    $chart->render_image(
        output => 'charts/bar.png',
        width  => 800,
        height => 600
    );

=begin html

<a href = "https://raw.githubusercontent.com/giterlizzi/perl-Chart-ECharts/main/charts/bar.png">
<img src = "https://raw.githubusercontent.com/giterlizzi/perl-Chart-ECharts/main/charts/bar.png"
     alt = "Bar Chart" />
</a>

=end html

=head1 DESCRIPTION

L<Chart::ECharts> is a distribution that works as a wrapper for the Apache Echarts js library.

L<https://echarts.apache.org/>


=head2 METHODS

=over

=item $chart = Chart::ECharts->new(%params)

B<Params>

=over

=item C<charts_object>, Charts object accessible via C<window> object (default C<ChartEcharts>)

=item C<class>, Chart container CSS class (default C<chart-container>)

=item C<container_prefix>, Default chart container prefix (default C<undef>)

=item C<events>, Events (default C<[]>)

=item C<height>, Chart height

=item C<id>, Chart ID (default C<chart_ + "random string">)

=item C<locale>, Chart locale (default C<en>)

=item C<options>, EChart options (L<https://echarts.apache.org/en/option.html>) (default C<{}>)

=item C<renderer>, Default ECharts renrerer (default C<canvas>)

=item C<responsive>, Enable responsive feature

=item C<series>, Chart series (L<https://echarts.apache.org/en/option.html#series>)

=item C<styles>, Default char styles (default C<['min-width:auto', 'min-height:300px']>)

=item C<theme>. Chart theme (default C<white>)

=item C<vertical>, Set the chart in vertical (default C<0>)

=item C<width>, Chart width

=item C<xAxis>, Chart X Axis (L<https://echarts.apache.org/en/option.html#xAxis>)

=item C<yAxis>, Chart Y Axis (L<https://echarts.apache.org/en/option.html#yAxis>)

=back

Return L<Chart::ECharts> object.

=item $chart->set_options(%options)

Set Apache EChart options (see Apache ECharts documentations L<https://echarts.apache.org/en/option.html>).

    $chart->set_options(
        title => {text => 'My Chart'},
        grid  => {left => 10, bottom => 10, right => 10, containLabel => \1}
    );

=item $chart->set_option(%params)

(DEPRECATED) Alias of C<set_options>

=item $chart->set_option_item($name, $params)

=item $chart->get_random_id

Get the random chart ID.

=item $chart->set_event($event, $callback)

Set a JS event.

    $chart->on('click', q{ console.log(params); });

=item $chart->on($event, $callback)

Alias of L<set_event>.

=item $chart->add_script($script)

Add custom JS script. All scripts are rendered via C<render_html> and C<render_script>.

    $chart->add_script(q{
        console.log('Hello World');
    });

=item $chart->add_xAxis(%axis)

Add single X axis (see Apache ECharts documentations L<https://echarts.apache.org/en/option.html#xAxis>).

    $chart->add_xAxis(
        type => 'category',
        data => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    );

=item $chart->set_xAxis(%axis)

Set X axis (see Apache ECharts documentations L<https://echarts.apache.org/en/option.html#xAxis>).

    $chart->set_xAxis(
        splitLine => {
            lineStyle => {
                type => 'dashed'
            }
        }
    );

=item $chart->add_yAxis(%axis)

Add single Y axis (see Apache ECharts documentations L<https://echarts.apache.org/en/option.html#yAxis>).

    $chart->add_yAxis(
        type => 'value'
    );

=item $chart->set_yAxis(%axis)

Set Y axis (see Apache ECharts documentations L<https://echarts.apache.org/en/option.html#yAxis>).

    $chart->set_yAxis(
        splitLine => {
            lineStyle => {
                type => 'dashed'
            }
        }
    );

=item $chart->add_series(%series)

Add single series (see Apache ECharts documentations L<https://echarts.apache.org/en/option.html#series>).

    $chart->add_series(
        name => 'series_name',
        type => 'bar',
        data => [120, 200, 150, 80, 70, 110, 130]
    );

=item $chart->js($expression)

Embed arbritaty JS code in chart options.

    $chart->set_tooltip(
        valueFormatter => $chart->js( q{(value) => '$' + Math.round(value)} )
    );

=back


=head3 OPTION HELPERS

=over

=item $chart->set_title(%params)

Set the chart title

=item $chart->set_toolbox(%params)

Set the chart toolbox

=item $chart->set_tooltip(%params)

Set the chart tooltip

=item $chart->set_legend(%params)

Set the chart legend

=item $chart->set_timeline(%params)

Set the chart timeline

=item $chart->set_data_zoom(%params)

Set the chart data zoom

=item $chart->add_data_zoom(%params)

Add the chart data zoom

=back


=head3 PROPERIES

=over

=item $chart->xAxis

Return X axis.

=item $chart->yAxis

Return Y axis.

=item $chart->series

Return chart series.

=item $chart->default_options

Return chart default options.

=item $chart->options

Return all chart options.

=item $chart->axies

Return X and Y axies.

=back


=head3 RENDERS

=over

=item $chart->render_script(%params)

Render the chart in JS.

    my $script = $chart->render_script;

=item $chart->render_html(%params)

Render the chart in HTML including the output of L<render_script> with a C<div> container.

=item $chart->render_image(%params)

Render the chart image file (require Node.js).

B<Parameters>

=over

=item C<node_path>, Node.js (aka C<node_modules>) path (default: C<$ENV{NODE_PATH}>)

=item C<node_bin>, Node.js binary (optional)

=item C<output>, Output file (required)

=item C<format>, Output file format (C<png> or C<svg>, optional)

=item C<width>, Image width (default: 400)

=item C<height>, Image height (default: 300)

=back

=item $chart->TO_JSON

Encode options in JSON.

=back

=head2 Embed Chart::ECharts in your web application:

=head3 Mojolicious

    use Mojolicious::Lite -signatures;

    helper render_chart => sub ($c, $chart) {
        Mojo::ByteStream->new($chart->render_html);
    };

    get '/chart' => sub ($c) {

        my $cool_chart = Chart::ECharts->new;

        # [...]

        $c->render('chart', cool_chart => $cool_chart);

    };

    app->start;

    __DATA__

    @@ default.html.ep
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title><%= title %></title>
        <!-- Include the ECharts file you just downloaded -->
        <script src="echarts.js"></script>
      </head>
      <body>
        %= content
      </body>
    </html>

    @@ chart.html.ep

    % layout 'default';
    % title 'My cool chart with Chart::ECharts';

    <h1>My cool chart with Chart::ECharts</h1>

    <p><% render_chart($cool_chart) %></p>

=head2 Setup Node.js

Install Apache ECharts >= 5.4 (L<https://www.npmjs.com/package/echarts>)
and Canvas >= 2.11 (L<https://www.npmjs.com/package/canvas>):

    $ cd your-project-path
    $ npm add canvas echarts

You can use the C<share/package.json> in the distribution directory:

    $ cd your-project-path
    $ cp <Chart-EChart-dist>/share/package.json .
    $ npm install

In your Perl script set the C<node_path> options (or set C<$ENV{NODE_PATH}> enviroment),
C<node_bin> if Node.js is not in C<$ENV{PATH}> and C<output> image file:

    local $ENV{NODE_PATH} = 'your-project-path/node_modules';

    $chart->render_image(
        output => 'charts/bar.png',
        width  => 800,
        height => 600
    );

=head2 Charts object

By default L<Chart::ECharts> expose an object in C<window.ChartECharts> object
(use C<charts_object> config to rename).

Properties:

=over

=item C<charts>, ARRAY of chart IDs

This property contains an ARRAY of all generated graphs (via C<render_html> and
C<render_script>). It is useful to allow customization of the graph via JS.

    my $chart = Chart::ECharts(id => 'myChart');

    # ...

    $chart->render_html;

    # in your JS

    if ('myChart' in window.ChartECharts.charts) {

        let myChart = window.ChartECharts.charts.myChart;

        let newLabels = [];
        let newData   = [];

        // Update chart data
        myChart.setOption({
            xAxis: {
                data: newLabels
            },
            series: [
                {
                    data: newData
                }
            ]
        });

    }

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
