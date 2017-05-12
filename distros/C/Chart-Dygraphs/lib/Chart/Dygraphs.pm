package Chart::Dygraphs;

use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(show_plot);

use JSON;
use Params::Validate qw(:all);
use Text::Template;
use HTML::Show;
use Ref::Util;

our $VERSION = '0.007';    # VERSION

# ABSTRACT: Generate html/javascript charts from perl data using javascript library Dygraphs

sub render_full_html {
    my %params = validate( @_,
                           {  data    => { type => SCALAR | ARRAYREF | OBJECT },
                              options => { type => HASHREF, default => { showRangeSelector => 1 } },
                              render_html_options => { type     => HASHREF,
                                                       optional => 1,
                                                       default  => {}
                              }
                           }
    );
    return _render_html_wrap(
           _render_cell( _process_data_and_options( @params{qw(data options)} ), $params{'render_html_options'}, '' ) );
}

sub _transform_data {
    my $data        = shift;
    my $string_data = "";
    if ( Ref::Util::is_plain_arrayref($data) ) {
        $string_data .= "[" . ( join( ',', map { _transform_data($_) } @$data ) ) . "]";
    } elsif ( Ref::Util::is_plain_hashref($data) ) {
        return "not supported";
    } elsif ( Ref::Util::is_blessed_ref($data) && $data->isa('DateTime') ) {
        return 'new Date("' . $data . '")';
    } else {
        return $data;
    }
    return $string_data;
}

sub _process_data_and_options {
    my $data           = shift();
    my $options        = shift();
    my $json_formatter = JSON->new->utf8;
    local *PDL::TO_JSON = sub { $_[0]->unpdl };
    if ( Ref::Util::is_blessed_ref($data) ) {
        my $adapter_name = 'Chart::Dygraphs::Adapter::' . ref $data;
        eval {
            load $adapter_name;
            my $adapter = $adapter_name->new( data => $data );
            $data = $adapter->series();
        };
        if ($@) {
            warn 'Cannot load adapter: ' . $adapter_name . '. ' . $@;
        }
    }
    return join( ',', _transform_data($data), $json_formatter->encode($options) );
}

sub _render_cell {

    my $data         = shift();
    my $html_options = shift();
    my $id           = shift();
    my $template     = <<'TEMPLATE';
{$pre_graph_html}
<div id="{$dygraphs_div_id}" style="{$dygraphs_div_inline_style}"></div>
<script type="text/javascript">
  {$dygraphs_javascript_object_name} = new Dygraph(
    document.getElementById("{$dygraphs_div_id}"),
    {$data_and_options}
  );

  var range = {$dygraphs_javascript_object_name}.yAxisRange(0);
  {$dygraphs_javascript_object_name}.updateOptions(\{valueRange: range\});
</script>
{$post_graph_html}
TEMPLATE
    my $template_variables = { %{$html_options}, data_and_options => $data, };

    if ( !defined $template_variables->{'dygraphs_div_id'} ) {
        $template_variables->{'dygraphs_div_id'} = 'graphdiv' . $id;
    }
    if ( !defined $template_variables->{'dygraphs_javascript_object_name'} ) {
        $template_variables->{'dygraphs_javascript_object_name'} = 'g' . $id;
    }
    if ( !defined $template_variables->{'dygraphs_div_inline_style'} ) {
        $template_variables->{'dygraphs_div_inline_style'} = 'width: 100%';
    }
    my $renderer = Text::Template->new( TYPE => 'STRING', SOURCE => $template );
    return $renderer->fill_in( HASH => $template_variables );
}

sub _render_html_wrap {
    my $body = shift();

    my $html_begin = <<'BEGIN_HTML';
<html>
<head>
<script src="https://cdnjs.cloudflare.com/ajax/libs/dygraph/1.1.1/dygraph-combined.js"></script>
</head>
<body>
BEGIN_HTML

    my $html_end = <<'END_HTML';
</body>
</html>
END_HTML

    return $html_begin . $body . $html_end;

}

sub show_plot {
    my @data_to_plot = @_;

    my $rendered_cells = "";
    my $numeric_id     = 0;
    for my $data (@data_to_plot) {
        if ( ref $data eq 'Chart::Dygraphs::Plot' ) {
            $rendered_cells .= _render_cell( _process_data_and_options( $data->data, $data->options ),
                                             {  dygraphs_div_id                 => 'graphdiv' . $numeric_id,
                                                dygraphs_javascript_object_name => 'g' . $numeric_id
                                             },
                                             'chart_' . $numeric_id++
            );

        } else {
            $rendered_cells .= _render_cell( _process_data_and_options( $data, { showRangeSelector => 1 } ),
                                             {  dygraphs_div_id                 => 'graphdiv' . $numeric_id,
                                                dygraphs_javascript_object_name => 'g' . $numeric_id
                                             },
                                             'chart_' . $numeric_id++
            );
        }
    }
    my $plots = _render_html_wrap($rendered_cells);
    HTML::Show::show($plots);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Dygraphs - Generate html/javascript charts from perl data using javascript library Dygraphs

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 use Chart::Dygraphs qw(show_plot);
 
 my $data = [map {[$_, rand($_)]} 1..10 ];
 show_plot($data);

 use Chart::Dygraphs qw(show_plot);
 use DateTime;
 
 my $start_date = DateTime->now(time_zone => 'UTC')->truncate(to => 'hour');
 my $time_series_data = [map {[$start_date->add(hours => 1)->clone(), rand($_)]} 1..1000];
 
 show_plot($time_series_data);

=head1 DESCRIPTION

Generate html/javascript charts from perl data using javascript library Dygraphs. The result
is html that you could see in your favourite browser.

Example screenshot of plot generated with examples/time_series.pl:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Dygraphs/master/examples/time_series.png" alt="Random time series plotted with Dygraphs">
</p>

=for markdown ![Random time series plotted with Dygraphs](https://raw.githubusercontent.com/pablrod/p5-Chart-Dygraphs/master/examples/time_series.png)

The API is subject to changes.

=head1 FUNCTIONS

=head2 render_full_html

=head3 Parameters

=over

=item * data:

Data to be represented. The format is the perl version of the data expected by Dygraphs: L<http://dygraphs.com/data.html>

=item * options:

Hashref with options for graph. The format is the perl version of the options expected by Dygraphs: L<http://dygraphs.com/options.html>
Optional

=item * render_html_options

Hashref with options controlling html output. With this you can inject html, javascript or styles.

Supported options:

=over

=item * pre_graph_html

=item * post_graph_html

=item * dygraphs_div_id

=item * dygraphs_javascript_object_name

=item * dygraphs_div_inline_style

=back

=back

=head2 show_plot

Opens the plot in a browser locally

=head3 Parameters

Data to be represented. The format is the same as the parameter data in render_full_html

=head1 AUTHOR

Pablo Rodríguez González

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Chart-Dygraphs/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pablo Rodríguez González.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES . THE IMPLIED WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR
              PURPOSE,                                 OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
              YOUR LOCAL LAW . UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
              CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
              CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
            EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
              .

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pablo Rodríguez González.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
