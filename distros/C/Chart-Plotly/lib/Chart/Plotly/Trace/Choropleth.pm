package Chart::Plotly::Trace::Choropleth;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Choropleth::Colorbar;
use Chart::Plotly::Trace::Choropleth::Hoverlabel;
use Chart::Plotly::Trace::Choropleth::Marker;
use Chart::Plotly::Trace::Choropleth::Selected;
use Chart::Plotly::Trace::Choropleth::Stream;
use Chart::Plotly::Trace::Choropleth::Transform;
use Chart::Plotly::Trace::Choropleth::Unselected;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: The data that describes the choropleth value-to-color mapping is set in `z`. The geographic locations corresponding to each value in `z` are set in `locations`.

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my $meta       = $self->meta;
    my %hash       = %$self;
    for my $name ( sort keys %hash ) {
        my $attr = $meta->get_attribute($name);
        if ( defined $attr ) {
            my $value = $hash{$name};
            my $type  = $attr->type_constraint;
            if ( $type && $type->equals('Bool') ) {
                $hash{$name} = $value ? \1 : \0;
            }
        }
    }
    my $plotly_meta = delete $hash{'pmeta'};
    if ( defined $plotly_meta ) {
        $hash{'meta'} = $plotly_meta;
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

has autocolorscale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.",
);

has coloraxis => (
    is => "rw",
    documentation =>
      "Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.",
);

has colorbar => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Choropleth::Colorbar", );

has colorscale => (
    is => "rw",
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`zmin` and `zmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.",
);

has customdata => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements",
);

has customdatasrc => ( is            => "rw",
                       isa           => "Str",
                       documentation => "Sets the source reference on plot.ly for  customdata .",
);

has geo => (
    is => "rw",
    documentation =>
      "Sets a reference between this trace's geospatial coordinates and a geographic map. If *geo* (the default value), the geospatial coordinates refer to `layout.geo`. If *geo2*, the geospatial coordinates refer to `layout.geo2`, and so on.",
);

has hoverinfo => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.",
);

has hoverinfosrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on plot.ly for  hoverinfo .",
);

has hoverlabel => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Choropleth::Hoverlabel", );

has hovertemplate => (
    is  => "rw",
    isa => "Str|ArrayRef[Str]",
    documentation =>
      "Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example \"y: %{y}\". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example \"Price: %{y:\$.2f}\". See https://github.com/d3/d3-format/blob/master/README.md#locale_format for details on the formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plot.ly/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available.  Anything contained in tag `<extra>` is displayed in the secondary box, for example \"<extra>{fullData.name}</extra>\". To hide the secondary box completely, use an empty tag `<extra></extra>`.",
);

has hovertemplatesrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on plot.ly for  hovertemplate .",
);

has hovertext => ( is            => "rw",
                   isa           => "Str|ArrayRef[Str]",
                   documentation => "Same as `text`.",
);

has hovertextsrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on plot.ly for  hovertext .",
);

has ids => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.",
);

has idssrc => ( is            => "rw",
                isa           => "Str",
                documentation => "Sets the source reference on plot.ly for  ids .",
);

has locationmode => (
         is            => "rw",
         isa           => enum( [ "ISO-3", "USA-states", "country names" ] ),
         documentation => "Determines the set of locations used to match entries in `locations` to regions on the map.",
);

has locations => ( is            => "rw",
                   isa           => "ArrayRef|PDL",
                   documentation => "Sets the coordinates via location IDs or names. See `locationmode` for more info.",
);

has locationssrc => ( is            => "rw",
                      isa           => "Str",
                      documentation => "Sets the source reference on plot.ly for  locations .",
);

has marker => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Choropleth::Marker", );

has pmeta => (
    is  => "rw",
    isa => "Any|ArrayRef[Any]",
    documentation =>
      "Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.",
);

has metasrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  meta .",
);

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has reversescale => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Reverses the color mapping if true. If true, `zmin` will correspond to the last color in the array and `zmax` will correspond to the first color.",
);

has selected => ( is  => "rw",
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Choropleth::Selected", );

has selectedpoints => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.",
);

has showscale => ( is            => "rw",
                   isa           => "Bool",
                   documentation => "Determines whether or not a colorbar is displayed for this trace.",
);

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Choropleth::Stream", );

has text => ( is            => "rw",
              isa           => "Str|ArrayRef[Str]",
              documentation => "Sets the text elements associated with each location.",
);

has textsrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  text .",
);

has transforms => ( is  => "rw",
                    isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Choropleth::Transform]", );

has uid => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.",
);

has uirevision => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.",
);

has unselected => ( is  => "rw",
                    isa => "Maybe[HashRef]|Chart::Plotly::Trace::Choropleth::Unselected", );

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

has z => ( is            => "rw",
           isa           => "ArrayRef|PDL",
           documentation => "Sets the color values.",
);

has zauto => (
    is  => "rw",
    isa => "Bool",
    documentation =>
      "Determines whether or not the color domain is computed with respect to the input data (here in `z`) or the bounds set in `zmin` and `zmax`  Defaults to `false` when `zmin` and `zmax` are set by the user.",
);

has zmax => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the upper bound of the color domain. Value should have the same units as in `z` and if set, `zmin` must be set as well.",
);

has zmid => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the mid-point of the color domain by scaling `zmin` and/or `zmax` to be equidistant to this point. Value should have the same units as in `z`. Has no effect when `zauto` is `false`.",
);

has zmin => (
    is  => "rw",
    isa => "Num",
    documentation =>
      "Sets the lower bound of the color domain. Value should have the same units as in `z` and if set, `zmax` must be set as well.",
);

has zsrc => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the source reference on plot.ly for  z .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Choropleth - The data that describes the choropleth value-to-color mapping is set in `z`. The geographic locations corresponding to each value in `z` are set in `locations`.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use HTML::Show;
 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Choropleth;
 
 my $countries = [ 'Afghanistan',                       'Albania',
                   'Algeria',                           'Andorra',
                   'Angola',                            'Antigua and Barbuda',
                   'Argentina',                         'Armenia',
                   'Australia',                         'Austria',
                   'Azerbaijan',                        'Bahamas',
                   'Bahrain',                           'Bangladesh',
                   'Barbados',                          'Belarus',
                   'Belgium',                           'Belize',
                   'Benin',                             'Bhutan',
                   'Bolivia',                           'Bosnia and Herzegovina',
                   'Botswana',                          'Brazil',
                   'Brunei',                            'Bulgaria',
                   'Burkina Faso',                      'Burundi',
                   'Cambodia',                          'Cameroon',
                   'Canada',                            'Cape Verde',
                   'Central African Republic',          'Chad',
                   'Chile',                             'China',
                   'Colombia',                          'Comoros',
                   'Congo, Democratic Republic of the', 'Congo, Republic of the',
                   'Costa Rica',                        'Croatia',
                   'Cuba',                              'Cyprus',
                   'Czech Republic',                    'Denmark',
                   'Djibouti',                          'Dominica',
                   'Dominican Republic',                'East Timor',
                   'Ecuador',                           'Egypt',
                   'El Salvador',                       'Equatorial Guinea',
                   'Eritrea',                           'Estonia',
                   'Ethiopia',                          'Fiji',
                   'Finland',                           'France',
                   'Gabon',                             'Gambia, The',
                   'Georgia',                           'Germany',
                   'Ghana',                             'Greece',
                   'Grenada',                           'Guatemala',
                   'Guinea',                            'Guinea-Bissau',
                   'Guyana',                            'Haiti',
                   'Honduras',                          'Hungary',
                   'Iceland',                           'India',
                   'Indonesia',                         'Iran',
                   'Iraq',                              'Ireland, Republic of',
                   'Israel',                            'Italy',
                   'Ivory Coast',                       'Jamaica',
                   'Japan',                             'Jordan',
                   'Kazakhstan',                        'Kenya',
                   'Kiribati',                          'Korea, North',
                   'Korea, South',                      'Kuwait',
                   'Kyrgyzstan',                        'Laos',
                   'Latvia',                            'Lebanon',
                   'Lesotho',                           'Liberia',
                   'Libya',                             'Liechtenstein',
                   'Lithuania',                         'Luxembourg',
                   'Macedonia, Republic of',            'Madagascar',
                   'Malawi',                            'Malaysia',
                   'Maldives',                          'Mali',
                   'Malta',                             'Marshall Islands',
                   'Mauritania',                        'Mauritius',
                   'Mexico',                            'Micronesia, Federated States of',
                   'Moldova',                           'Monaco',
                   'Mongolia',                          'Montenegro',
                   'Morocco',                           'Mozambique',
                   'Myanmar',                           'Namibia',
                   'Nepal',                             'Netherlands, Kingdom of the',
                   'New Zealand',                       'Nicaragua',
                   'Niger',                             'Nigeria',
                   'Norway',                            'Oman',
                   'Pakistan',                          'Palau',
                   'Panama',                            'Papua New Guinea',
                   'Paraguay',                          'Peru',
                   'Philippines',                       'Poland',
                   'Portugal',                          'Qatar',
                   'Romania',                           'Russia',
                   'Rwanda',                            'Saint Kitts and Nevis',
                   'Saint Lucia',                       'Saint Vincent and the Grenadines',
                   'Samoa',                             'San Marino',
                   'Sao Tome and Principe',             'Saudi Arabia',
                   'Senegal',                           'Serbia',
                   'Seychelles',                        'Sierra Leone',
                   'Singapore',                         'Slovakia',
                   'Slovenia',                          'Solomon Islands',
                   'Somalia',                           'South Africa',
                   'Spain',                             'Sri Lanka',
                   'Sudan',                             'Suriname',
                   'Swaziland',                         'Sweden',
                   'Switzerland',                       'Syria',
                   'Tajikistan',                        'Tanzania',
                   'Thailand',                          'Togo',
                   'Tonga',                             'Trinidad and Tobago',
                   'Tunisia',                           'Turkey',
                   'Turkmenistan',                      'Tuvalu',
                   'Uganda',                            'Ukraine',
                   'United Arab Emirates',              'United Kingdom',
                   'United States',                     'Uruguay',
                   'Uzbekistan',                        'Vanuatu',
                   'Venezuela',                         'Vietnam',
                   'Yemen',                             'Zambia',
                   'Zimbabwe'
 ];
 
 my $avg_temperature = [ 12.6,  11.4,  22.5,  7.6,   21.55, 26,    14.8,  7.15,  21.65, 6.35,  11.95, 24.85,
                         27.15, 25,    26,    6.15,  9.55,  25.3,  27.55, 7.4,   21.55, 9.85,  21.5,  24.95,
                         26.85, 10.55, 28.25, 19.8,  26.8,  24.6,  -5.35, 23.3,  24.9,  26.55, 8.45,  6.95,
                         24.5,  25.55, 24,    24.55, 24.8,  10.9,  25.2,  18.45, 7.55,  7.5,   28,    22.35,
                         24.55, 25.25, 21.85, 22.1,  24.45, 24.55, 25.5,  5.1,   22.2,  24.4,  1.7,   10.7,
                         25.05, 27.5,  5.8,   8.5,   27.2,  15.4,  26.65, 23.45, 25.7,  26.75, 26,    24.9,
                         23.5,  9.75,  1.75,  23.65, 25.85, 17.25, 21.4,  9.3,   19.2,  13.45, 26.35, 24.95,
                         11.15, 18.3,  6.4,   24.75, 28.2,  5.7,   11.5,  25.35, 1.55,  22.8,  5.6,   16.4,
                         11.85, 25.3,  21.8,  5.65,  6.2,   8.65,  9.8,   22.65, 21.9,  25.4,  27.65, 28.25,
                         19.2,  27.4,  27.65, 22.4,  21,    25.85, 9.45,  13.55, -0.7,  10.55, 17.1,  23.8,
                         13.05, 19.95, 8.1,   9.25,  10.55, 24.9,  27.15, 26.8,  1.5,   25.6,  20.2,  27.6,
                         25.4,  25.25, 23.55, 19.6,  25.85, 7.85,  15.15, 27.15, 8.8,   -5.1,  17.85, 24.5,
                         25.5,  26.8,  26.7,  11.85, 23.75, 24.65, 27.85, 10.55, 27.15, 26.05, 26.45, 6.8,
                         8.9,   25.65, 27.05, 17.75, 13.3,  26.95, 26.9,  25.7,  21.4,  2.1,   5.5,   17.75,
                         2,     22.35, 26.3,  27.15, 25.25, 25.75, 19.2,  11.1,  15.1,  28,    22.8,  8.3,
                         27,    8.45,  8.55,  17.55, 12.05, 23.95, 25.35, 24.45, 23.85, 21.4,  21
 ];
 
 my $choropleth = Chart::Plotly::Trace::Choropleth->new( locationmode   => 'country names',
                                                         locations      => $countries,
                                                         z              => $avg_temperature,
                                                         text           => $countries,
                                                         autocolorscale => 1
 );
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [$choropleth],
     layout => {
         title => 'Average temperature by country
     Source: https://en.wikipedia.org/wiki/List_of_countries_by_average_yearly_temperature',
         geo => { projection => { type => 'robinson' } }
     }
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

The data that describes the choropleth value-to-color mapping is set in `z`. The geographic locations corresponding to each value in `z` are set in `locations`.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/choropleth.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/choropleth.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/choropleth.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#choropleth>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head2 type

Trace type.

=head1 ATTRIBUTES

=over

=item * autocolorscale

Determines whether the colorscale is a default palette (`autocolorscale: true`) or the palette determined by `colorscale`. In case `colorscale` is unspecified or `autocolorscale` is true, the default  palette will be chosen according to whether numbers in the `color` array are all positive, all negative or mixed.

=item * coloraxis

Sets a reference to a shared color axis. References to these shared color axes are *coloraxis*, *coloraxis2*, *coloraxis3*, etc. Settings for these shared color axes are set in the layout, under `layout.coloraxis`, `layout.coloraxis2`, etc. Note that multiple color scales can be linked to the same color axis.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in color space, use`zmin` and `zmax`. Alternatively, `colorscale` may be a palette name string of the following list: Greys,YlGnBu,Greens,YlOrRd,Bluered,RdBu,Reds,Blues,Picnic,Rainbow,Portland,Jet,Hot,Blackbody,Earth,Electric,Viridis,Cividis.

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on plot.ly for  customdata .

=item * geo

Sets a reference between this trace's geospatial coordinates and a geographic map. If *geo* (the default value), the geospatial coordinates refer to `layout.geo`. If *geo2*, the geospatial coordinates refer to `layout.geo2`, and so on.

=item * hoverinfo

Determines which trace information appear on hover. If `none` or `skip` are set, no information is displayed upon hovering. But, if `none` is set, click and hover events are still fired.

=item * hoverinfosrc

Sets the source reference on plot.ly for  hoverinfo .

=item * hoverlabel

=item * hovertemplate

Template string used for rendering the information that appear on hover box. Note that this will override `hoverinfo`. Variables are inserted using %{variable}, for example "y: %{y}". Numbers are formatted using d3-format's syntax %{variable:d3-format}, for example "Price: %{y:$.2f}". See https://github.com/d3/d3-format/blob/master/README.md#locale_format for details on the formatting syntax. The variables available in `hovertemplate` are the ones emitted as event data described at this link https://plot.ly/javascript/plotlyjs-events/#event-data. Additionally, every attributes that can be specified per-point (the ones that are `arrayOk: true`) are available.  Anything contained in tag `<extra>` is displayed in the secondary box, for example "<extra>{fullData.name}</extra>". To hide the secondary box completely, use an empty tag `<extra></extra>`.

=item * hovertemplatesrc

Sets the source reference on plot.ly for  hovertemplate .

=item * hovertext

Same as `text`.

=item * hovertextsrc

Sets the source reference on plot.ly for  hovertext .

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on plot.ly for  ids .

=item * locationmode

Determines the set of locations used to match entries in `locations` to regions on the map.

=item * locations

Sets the coordinates via location IDs or names. See `locationmode` for more info.

=item * locationssrc

Sets the source reference on plot.ly for  locations .

=item * marker

=item * pmeta

Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.

=item * metasrc

Sets the source reference on plot.ly for  meta .

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * reversescale

Reverses the color mapping if true. If true, `zmin` will correspond to the last color in the array and `zmax` will correspond to the first color.

=item * selected

=item * selectedpoints

Array containing integer indices of selected points. Has an effect only for traces that support selections. Note that an empty array means an empty selection where the `unselected` are turned on for all points, whereas, any other non-array values means no selection all where the `selected` and `unselected` styles have no effect.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * stream

=item * text

Sets the text elements associated with each location.

=item * textsrc

Sets the source reference on plot.ly for  text .

=item * transforms

=item * uid

Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

=item * unselected

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=item * z

Sets the color values.

=item * zauto

Determines whether or not the color domain is computed with respect to the input data (here in `z`) or the bounds set in `zmin` and `zmax`  Defaults to `false` when `zmin` and `zmax` are set by the user.

=item * zmax

Sets the upper bound of the color domain. Value should have the same units as in `z` and if set, `zmin` must be set as well.

=item * zmid

Sets the mid-point of the color domain by scaling `zmin` and/or `zmax` to be equidistant to this point. Value should have the same units as in `z`. Has no effect when `zauto` is `false`.

=item * zmin

Sets the lower bound of the color domain. Value should have the same units as in `z` and if set, `zmax` must be set as well.

=item * zsrc

Sets the source reference on plot.ly for  z .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
